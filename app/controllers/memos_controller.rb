class MemosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_memo, only: [ :edit, :update, :destroy ]

def index
  @q = params[:q].to_s.strip
  @tag_id = params[:tag_id]
  @selected_tag = current_user.tags.find_by(id: @tag_id) if @tag_id.present?
  @memos = current_user.memos.includes(:tags).order(created_at: :desc)

  # 絞り込み時にタグ名を表示
  if @tag_id.present?
    @memos = @memos.joins(:memo_tags).where(memo_tags: { tag_id: @tag_id })
  end

  # キーワード検索（複数カラムを対象）
  if @q.present?
    like = "%#{ActiveRecord::Base.sanitize_sql_like(@q)}%"
    @memos = @memos.left_joins(:tags).where(
      "memos.symptom ILIKE :q OR memos.check_point ILIKE :q OR memos.judgment ILIKE :q OR memos.concern_point ILIKE :q OR memos.reflection ILIKE :q OR tags.name ILIKE :q",
      q: like
    )
  end

    @memos = @memos.distinct
    @tags = current_user.tags
      .joins(:memos)   # memosと紐づくタグだけ
      .where(memos: { user_id: current_user.id })
      .distinct
      .order(:name)
end

  # タグで絞り込み（ANDで追加）
  if @tag_id.present?
    @memos = @memos.joins(:memo_tags).where(memo_tags: { tag_id: @tag_id })
  end

  def new
    @memo = current_user.memos.build
  end

  def create
    @memo = current_user.memos.build(memo_params.except(:tag_names))
    if @memo.save
      save_tags(@memo, memo_params[:tag_names])
      redirect_to memos_path, notice: t("flash.memo.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  # edit を「詳細兼編集」として使う
  def edit
  end

  def update
    if @memo.update(memo_params.except(:tag_names))
      save_tags(@memo, memo_params[:tag_names])
      redirect_to memos_path, notice: t("flash.memo.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @memo.destroy
    redirect_to memos_path, notice: t("flash.memo.destroyed")
  end

private

  # 他ユーザーのメモにアクセスできないよう current_user 経由で取得
  def set_memo
    @memo = current_user.memos.find(params[:id])
  end

  def memo_params
    params.require(:memo).permit(:symptom, :check_point, :judgment, :concern_point, :reflection, :tag_names)
  end

  def save_tags(memo, tag_names)
    names = (tag_names || "")
              .split(/[,\s]+/)  # カンマ/空白区切り
              .map { |s| s.strip }
              .reject(&:blank?)
              .uniq

    tags = names.map do |name|
      # 同じユーザー内でタグを再利用
      current_user.tags.find_or_create_by!(name: name)
    end

    memo.tags = tags
  end
end
