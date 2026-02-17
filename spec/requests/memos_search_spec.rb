  # 検索（q + tag_id 併用）テスト
require "rails_helper"

RSpec.describe "Memos search", type: :request do
  let(:user) { create(:user) }

  it "qで絞り込める" do
    sign_in user
    create(:memo, user: user, symptom: "頭痛")
    create(:memo, user: user, symptom: "腹痛")

    get memos_path, params: { q: "頭痛" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("頭痛")
    expect(response.body).not_to include("腹痛")
  end

  it "tag_idで絞り込める" do
    sign_in user

    tag_a = create(:tag, name: "頭痛")
    tag_b = create(:tag, name: "花粉")

    memo1 = create(:memo, user: user, symptom: "頭痛メモ")
    memo2 = create(:memo, user: user, symptom: "花粉メモ")

    create(:memo_tag, memo: memo1, tag: tag_a)
    create(:memo_tag, memo: memo2, tag: tag_b)

    get memos_path, params: { tag_id: tag_a.id }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("頭痛メモ")
    expect(response.body).not_to include("花粉メモ")
  end

  it "qとtag_idを併用できる" do
    sign_in user

    tag = create(:tag, name: "頭痛")
    memo_ok = create(:memo, user: user, symptom: "頭痛で市販薬")
    memo_ng1 = create(:memo, user: user, symptom: "頭痛で受診")
    memo_ng2 = create(:memo, user: user, symptom: "腹痛で市販薬")

    create(:memo_tag, memo: memo_ok, tag: tag)
    create(:memo_tag, memo: memo_ng1, tag: tag)

    get memos_path, params: { q: "市販薬", tag_id: tag.id }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("頭痛で市販薬")
    expect(response.body).not_to include("頭痛で受診")
    expect(response.body).not_to include("腹痛で市販薬")
  end
end
