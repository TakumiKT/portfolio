require "rails_helper"

RSpec.describe "Memos search", type: :request do
  include LoginHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  before { sign_in_as(user) } # ← いまのログインヘルパー名に合わせて

  it "qで絞り込める" do
    create(:memo, :published, user: user, symptom: "頭痛")
    create(:memo, :published, user: user, symptom: "腹痛")

    get memos_path, params: { q: "頭痛" }
    follow_redirect! while response.redirect?
    puts response.status
    puts response.body.include?("開始日") # 画面に開始日が出るようなら true
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("頭痛")
    expect(response.body).not_to include("腹痛")
  end

  it "tag_idで絞り込める" do
    tag = create(:tag, user: user, name: "かぜ")
    m1 = create(:memo, :published, user: user, symptom: "A")
    m2 = create(:memo, :published, user: user, symptom: "B")

    create(:memo_tag, memo: m1, tag: tag)

    get memos_path, params: { tag_id: tag.id }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("A")
    expect(response.body).not_to include("B")
  end

  it "qとtag_idを併用できる" do
    tag = create(:tag, user: user, name: "小児")
    m1 = create(:memo, :published, user: user, symptom: "発熱")
    m2 = create(:memo, :published, user: user, symptom: "頭痛")

    create(:memo_tag, memo: m1, tag: tag)
    create(:memo_tag, memo: m2, tag: tag)

    get memos_path, params: { q: "発熱", tag_id: tag.id }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("発熱")
    expect(response.body).not_to include("頭痛")
  end

  it "drafts=1 のとき下書きのみ表示される" do
    create(:memo, :draft, user: user, symptom: "下書きA")
    create(:memo, :published, user: user, symptom: "清書B")

    get memos_path, params: { drafts: 1 }
    expect(response.body).to include("下書きA")
    expect(response.body).not_to include("清書B")
  end

  it "published=1 のとき清書のみ表示される" do
    create(:memo, :draft, user: user, symptom: "下書きA")
    create(:memo, :published, user: user, symptom: "清書B")

    get memos_path, params: { published: 1 }
    expect(response.body).to include("清書B")
    expect(response.body).not_to include("下書きA")
  end

  it "日付範囲で絞り込める（from/to）" do
    travel_to(Time.zone.parse("2026-01-01 12:00:00")) do
      create(:memo, :published, user: user, symptom: "ZZZ_OLD_20260101")
    end
    travel_to(Time.zone.parse("2026-02-15 12:00:00")) do
      create(:memo, :published, user: user, symptom: "ZZZ_NEW_20260215")
    end

    # デバッグしたいならここ（任意）
    # puts Memo.order(:created_at).pluck(:symptom, :created_at).inspect
    puts Memo.order(:created_at).pluck(:symptom, :created_at).inspect
    get memos_path, params: { from_date: "2026-02-01", to_date: "2026-02-28", published: 1 }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("ZZZ_NEW_20260215")
    expect(response.body).not_to include("ZZZ_OLD_20260101")
  end

  it "sort=oldest で古い順になる（ざっくり確認）" do
    m1 = create(:memo, :published, user: user, symptom: "A")
    m2 = create(:memo, :published, user: user, symptom: "B")

    m1.update!(created_at: 2.days.ago)
    m2.update!(created_at: 1.day.ago)

    get memos_path, params: { sort: "oldest" }
    body = response.body

    expect(body.index("A")).to be < body.index("B")
  end
end
