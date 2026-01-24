class MemosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_memo, only: [:edit, :update, :destroy]

  def index
    @memos = current_user.memos.order(created_at: :desc)
  end

  def new
    @memo = current_user.memos.build
  end

  def create
    @memo = current_user.memos.build(memo_params)
    if @memo.save
      redirect_to memos_path, notice: "メモを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # edit を「詳細兼編集」として使う
  def edit
  end

  def update
    if @memo.update(memo_params)
      redirect_to memos_path, notice: "メモを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @memo.destroy
    redirect_to memos_path, notice: "メモを削除しました"
  end

  private

  # 他ユーザーのメモにアクセスできないよう制御 current_user 経由で取得
  def set_memo
    @memo = current_user.memos.find(params[:id])
  end

  def memo_params
    params.require(:memo).permit(:symptom, :check_point, :judgment, :concern_point, :reflection)
  end
end
