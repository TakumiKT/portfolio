require "rails_helper"

RSpec.describe Ai::ReportService do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  after { travel_back }

  def stub_openai_report(content: "REPORT_OK")
    client = instance_double(OpenaiClient)
    allow(OpenaiClient).to receive(:new).and_return(client)
    allow(client).to receive(:report_for_memos).and_return(
      { content: content, model: "gpt-4.1-mini", prompt_version: "v1" }
    )
    client
  end

  def create_published_memo!(symptom:, created_at:)
    create(:memo, :published, user: user, symptom: symptom, judgment: "判断", created_at: created_at).tap do |m|
      tag = create(:tag, user: user, name: "タグ#{symptom}")
      create(:memo_tag, memo: m, tag: tag)
    end
  end

  it "条件に合うメモからレポート生成し、AiResult(kind=report, memo_id=nil)を保存し、AiUsageが+1される" do
    travel_to(Time.zone.parse("2026-03-27 12:00:00")) do
      client = stub_openai_report(content: "REPORT_1")

      create_published_memo!(symptom: "A", created_at: 3.days.ago)
      create_published_memo!(symptom: "B", created_at: 2.days.ago)
      create_published_memo!(symptom: "C", created_at: 1.day.ago)

      service = described_class.new(user: user)

      params = {
        q: "",
        tag_id: "",
        from_date: "",
        to_date: "",
        search_in: "all",
        sort: "newest",
        limit: "2",
        favorites: "" # false
      }

      expect { service.call!(params: params) }
        .to change { user.ai_results.where(kind: "report").count }.by(1)
        .and change { user.ai_usages.find_by(date: Time.zone.today)&.count.to_i }.from(0).to(1)

      report = user.ai_results.where(kind: "report").order(created_at: :desc).first
      expect(report.memo_id).to be_nil
      expect(report.content).to include("REPORT_1")
      expect(report.model).to eq("gpt-4.1-mini")
      expect(report.prompt_version).to eq("v1")

      expect(client).to have_received(:report_for_memos).once
    end
  end

  it "同一条件（同一digest）は再利用し、OpenAIを呼ばずAiUsageも増えない" do
    travel_to(Time.zone.parse("2026-03-27 12:00:00")) do
      client = stub_openai_report(content: "REPORT_1")

      create_published_memo!(symptom: "A", created_at: 2.days.ago)
      create_published_memo!(symptom: "B", created_at: 1.day.ago)

      service = described_class.new(user: user)
      params = { search_in: "all", sort: "newest", limit: "30" }

      # 1回目
      service.call!(params: params)
      usage = user.ai_usages.find_by(date: Time.zone.today)
      expect(usage.count).to eq(1)

      # 2回目（同条件）
      expect { service.call!(params: params) }
        .not_to change { user.ai_results.where(kind: "report").count }

      usage.reload
      expect(usage.count).to eq(1)

      expect(client).to have_received(:report_for_memos).once
    end
  end

  it "条件が変わると再生成され、AiUsageも増える（例: sort変更）" do
    travel_to(Time.zone.parse("2026-03-27 12:00:00")) do
      client = stub_openai_report(content: "REPORT_1")

      create_published_memo!(symptom: "A", created_at: 2.days.ago)
      create_published_memo!(symptom: "B", created_at: 1.day.ago)

      service = described_class.new(user: user)

      params1 = { search_in: "all", sort: "newest", limit: "30" }
      params2 = { search_in: "all", sort: "oldest", limit: "30" } # range_labelが変わる

      service.call!(params: params1)
      expect(user.ai_usages.find_by(date: Time.zone.today).count).to eq(1)

      expect { service.call!(params: params2) }
        .to change { user.ai_results.where(kind: "report").count }.by(1)

      expect(user.ai_usages.find_by(date: Time.zone.today).count).to eq(2)
      expect(client).to have_received(:report_for_memos).twice
    end
  end

  it "対象メモが0件ならArgumentErrorになる" do
    travel_to(Time.zone.parse("2026-03-27 12:00:00")) do
      stub_openai_report

      service = described_class.new(user: user)

      expect { service.call!(params: { limit: "30" }) }
        .to raise_error(ArgumentError, /対象のメモがありません/)
    end
  end

  it "回数制限（daily_limit=3）を超えるとLimitExceededになる（AiUsageは増えない）" do
    travel_to(Time.zone.parse("2026-03-27 12:00:00")) do
      stub_openai_report

      # 対象メモが0だと先にArgumentErrorになるので、最低1件作る
      create_published_memo!(symptom: "A", created_at: 1.day.ago)

      service = described_class.new(user: user)

      # digestが変わるように条件を変えて3回生成
      service.call!(params: { limit: "10", sort: "newest", search_in: "all" })
      service.call!(params: { limit: "11", sort: "newest", search_in: "all" })
      service.call!(params: { limit: "12", sort: "newest", search_in: "all" })

      usage = user.ai_usages.find_by(date: Time.zone.today)
      expect(usage.count).to eq(3)

      # 4回目は制限
      expect { service.call!(params: { limit: "13", sort: "newest", search_in: "all" }) }
        .to raise_error(Ai::Generator::LimitExceeded)

      usage.reload
      expect(usage.count).to eq(3)
    end
  end
end