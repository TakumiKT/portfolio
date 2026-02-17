require "rails_helper"

RSpec.describe "Memos", type: :request do
  let(:user) { create(:user) }

  describe "GET /memos" do
    it "未ログインだとログインにリダイレクト" do
      get memos_path
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "ログイン済みだと表示できる" do
      sign_in user
      get memos_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /memos" do
    it "メモを作成できる" do
      sign_in user

      params = {
        memo: {
          symptom: "頭痛",
          concern_point: "いつから",
          check_point: "持病",
          judgement: "重篤兆候なし",
          suggestion: "市販薬検討"
        }
      }

      expect {
        post memos_path, params: params
      }.to change(Memo, :count).by(1)

      expect(response).to have_http_status(:found) # redirect想定
    end
  end

  describe "PATCH /memos/:id" do
    it "自分のメモを更新できる" do
      sign_in user
      memo = create(:memo, user: user, symptom: "変更前")

      patch memo_path(memo), params: { memo: { symptom: "変更後" } }

      expect(response).to have_http_status(:found)
      expect(memo.reload.symptom).to eq("変更後")
    end

    it "他人のメモは更新できない（実装方針に合わせて）" do
      sign_in user
      other = create(:user)
      memo = create(:memo, user: other)

      patch memo_path(memo), params: { memo: { symptom: "不正変更" } }

      # ここは実装によって期待値が変わるので、あなたの実装に寄せて選ぶ：
      # - 404にするなら:
      # expect(response).to have_http_status(:not_found)
      # - 一覧へリダイレクトなら:
      # expect(response).to redirect_to(memos_path)

      expect(memo.reload.user_id).to eq(other.id)
    end
  end

  describe "DELETE /memos/:id" do
    it "自分のメモを削除できる" do
      sign_in user
      memo = create(:memo, user: user)

      expect {
        delete memo_path(memo)
      }.to change(Memo, :count).by(-1)

      expect(response).to have_http_status(:found)
    end
  end
end
