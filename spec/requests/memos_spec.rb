require "rails_helper"

RSpec.describe "Memos", type: :request do
  include LoginHelper

  let(:user) { create(:user) }
  let(:other) { create(:user) }

  before { login_as(user) }

  it "自分のメモを作成できる" do
    post memos_path, params: {
      memo: {
        symptom: "作成",
        check_point: "確認",
        judgment: "判断",
        concern_point: "",
        reflection: "",
        tag_names: "かぜ, 小児"
      },
      commit_action: "publish"
    }
    expect(response).to redirect_to(memos_path)
    expect(Memo.last.symptom).to eq("作成")
    expect(Memo.last.tags.pluck(:name)).to include("かぜ", "小児")
  end

  it "他人のメモは編集ページを表示できない（方針に合わせて）" do
    memo = create(:memo, :published, user: other)
    get edit_memo_path(memo)
    # 実装に合わせて 404 or リダイレクトなどを期待値にする
    expect(response).not_to have_http_status(:ok)
  end
end
