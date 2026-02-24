class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_memo

  def create
    current_user.favorites.find_or_create_by!(memo: @memo)
    redirect_back fallback_location: memos_path, notice: "お気に入りに追加しました"
  end

  def destroy
    current_user.favorites.where(memo: @memo).destroy_all
    redirect_back fallback_location: memos_path, notice: "お気に入りを解除しました"
  end

  private

  def set_memo
    # 自分のメモだけ対象
    @memo = current_user.memos.find(params[:memo_id])
  end
end