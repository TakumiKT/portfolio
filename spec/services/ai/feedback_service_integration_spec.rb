require "rails_helper"

RSpec.describe Ai::FeedbackService do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:memo) { create(:memo, :published, user: user, symptom: "頭痛", judgment: "受診勧奨の要否を判断") }

  before do
    # タグ付与（tag_namesの生成が安定するように）
    tag1 = create(:tag, user: user, name: "かぜ")
    tag2 = create(:tag, user: user, name: "小児")
    create(:memo_tag, memo: memo, tag: tag2)
    create(:memo_tag, memo: memo, tag: tag1)
  end

  after { travel_back }

  def stub_openai(content: "OK")
    client = instance_double(OpenaiClient)
    allow(OpenaiClient).to receive(:new).and_return(client)
    allow(client).to receive(:feedback_for_memo).and_return(
      { content: content, model: "gpt-4.1-mini", prompt_version: "v1" }
    )
    client
  end

  it "初回はOpenAIを呼んでAiResultを保存し、AiUsageが+1される" do
    travel_to(Time.zone.parse("2026-03-27 12:00:00")) do
      client = stub_openai(content: "FEEDBACK")

      service = described_class.new(user: user)

      expect { service.call!(memo: memo) }
        .to change { AiResult.count }.by(1)
        .and change { user.ai_usages.find_by(date: Time.zone.today)&.count.to_i }.from(0).to(1)

      ai = user.ai_results.order(created_at: :desc).first
      expect(ai.kind).to eq("feedback")
      expect(ai.memo_id).to eq(memo.id)
      expect(ai.content).to include("FEEDBACK")
      expect(ai.model).to eq("gpt-4.1-mini")
      expect(ai.prompt_version).to eq("v1")

      expect(client).to have_received(:feedback_for_memo).once
    end
  end

  it "同一入力（同一digest）は再利用し、OpenAIを呼ばずAiUsageも増えない" do
    travel_to(Time.zone.parse("2026-03-27 12:00:00")) do
      client = stub_openai(content: "FEEDBACK")

      service = described_class.new(user: user)

      # 1回目
      service.call!(memo: memo)
      usage = user.ai_usages.find_by(date: Time.zone.today)
      expect(usage.count).to eq(1)

      # 2回目（同じmemo内容なので同一digestのはず）
      expect { service.call!(memo: memo) }
        .not_to change { AiResult.count }

      usage.reload
      expect(usage.count).to eq(1) # 増えない

      expect(client).to have_received(:feedback_for_memo).once # 1回目のみ
    end
  end

  it "内容が変わると再生成され、AiUsageが増える" do
    travel_to(Time.zone.parse("2026-03-27 12:00:00")) do
      client = stub_openai(content: "FEEDBACK")

      service = described_class.new(user: user)

      service.call!(memo: memo)

      # memo内容を変える（digestが変わる）
      memo.update!(symptom: "腹痛")

      expect { service.call!(memo: memo) }
        .to change { AiResult.count }.by(1)

      usage = user.ai_usages.find_by(date: Time.zone.today)
      expect(usage.count).to eq(2)

      expect(client).to have_received(:feedback_for_memo).twice
    end
  end

  it "回数制限を超えるとLimitExceededになる（=AiUsageが増えない）" do
    travel_to(Time.zone.parse("2026-03-27 12:00:00")) do
      # daily_limit=3 の想定（Generatorのバグを直した上でのテスト）
      stub_openai(content: "FEEDBACK")
      service = described_class.new(user: user)

      # 同一memoだと再利用で回数が増えないので、digestを変えるために内容を変えながら3回生成
      service.call!(memo: memo)
      memo.update!(symptom: "腹痛"); service.call!(memo: memo)
      memo.update!(symptom: "発熱"); service.call!(memo: memo)

      usage = user.ai_usages.find_by(date: Time.zone.today)
      expect(usage.count).to eq(3)

      memo.update!(symptom: "咳") # 4回目は新規digest
      expect { service.call!(memo: memo) }.to raise_error(Ai::Generator::LimitExceeded)

      usage.reload
      expect(usage.count).to eq(3) # 増えない
    end
  end
end
