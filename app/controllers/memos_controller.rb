class MemosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_memo, only: [ :edit, :update, :destroy ]

def index
  @q = params[:q].to_s.strip
  @tag_id = params[:tag_id]
  @selected_tag = current_user.tags.find_by(id: @tag_id) if @tag_id.present?
  @memos = current_user.memos.includes(:tags)
  @favorite_memo_ids = current_user.favorites.pluck(:memo_id) # N+1対策
  @from_date = params[:from_date].to_s.strip
  @to_date   = params[:to_date].to_s.strip
  @search_in = params[:search_in].presence || "all"   # all / symptom / judgment
  @sort      = params[:sort].presence || "newest"     # newest / oldest

  # タグ絞り込み
  if @tag_id.present?
    @memos = @memos.joins(:memo_tags).where(memo_tags: { tag_id: @tag_id })
  end

  # お気に入りのみ
  if params[:favorites].present?
    @memos = @memos.joins(:favorites).where(favorites: { user_id: current_user.id })
  end

  # 状態フィルタ（デフォルトは清書のみ）
  if params[:drafts].present?
    @memos = @memos.draft
  elsif params[:published].present?
    @memos = @memos.published
  else
    @memos = @memos.published
  end

  # キーワード検索（検索対象切替）
  if @q.present?
    like = "%#{ActiveRecord::Base.sanitize_sql_like(@q)}%"

    case @search_in
    when "symptom"
      @memos = @memos.where("memos.symptom ILIKE :q", q: like)
    when "judgment"
      @memos = @memos.where("memos.judgment ILIKE :q", q: like)
    else
      @memos = @memos.left_joins(:tags).where(
        "memos.symptom ILIKE :q OR memos.check_point ILIKE :q OR memos.judgment ILIKE :q OR memos.concern_point ILIKE :q OR memos.reflection ILIKE :q OR tags.name ILIKE :q",
        q: like
      )
    end
  end

  # 日付範囲
  if @from_date.present?
    begin
      from = Date.parse(@from_date)
      @memos = @memos.where("memos.created_at >= ?", from.beginning_of_day)
    rescue ArgumentError
      flash.now[:alert] = "開始日の形式が正しくありません"
    end
  end

  if @to_date.present?
    begin
      to = Date.parse(@to_date)
      @memos = @memos.where("memos.created_at <= ?", to.end_of_day)
    rescue ArgumentError
      flash.now[:alert] = "終了日の形式が正しくありません"
    end
  end

  # 並び順
  case @sort
  when "oldest"
    @memos = @memos.order(created_at: :asc)
  else
    @memos = @memos.order(created_at: :desc)
  end

  @memos = @memos.distinct

  @tags = current_user.tags
                     .joins(:memos)
                     .where(memos: { user_id: current_user.id })
                     .distinct
                     .order(:name)
end

def new
  @memo = current_user.memos.build
  @templates = current_user.templates.order(:name)

  if params[:template_id].present?
    @selected_template = current_user.templates.find_by(id: params[:template_id])
    apply_template_defaults(@memo, @selected_template) if @selected_template
  end
end

  def create
    @memo = current_user.memos.build(memo_params)
    @memo.status = (params[:commit_action] == "draft" ? :draft : :published)

    if @memo.save
      redirect_to memos_path, notice: (@memo.draft? ? "下書きとして保存しました" : "メモを作成しました")
    else
      flash.now[:alert] = "メモの作成に失敗しました"
      render :new, status: :unprocessable_entity
    end
  end

  # edit を「詳細兼編集」として使う
  def edit
    @templates = current_user.templates.order(:name)

    if params[:template_id].present?
      @selected_template = current_user.templates.find_by(id: params[:template_id])
      apply_template_defaults(@memo, @selected_template) if @selected_template
    end
  end

  def update
    @memo.status = (params[:commit_action] == "draft" ? :draft : :published)

    if @memo.update(memo_params)
      redirect_to memos_path, notice: (@memo.draft? ? "下書きを更新しました" : "メモを更新しました")
    else
      flash.now[:alert] = "メモの更新に失敗しました"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @memo.destroy
    redirect_to memos_path, notice: t("flash.memo.destroyed")
  end

def ai_feedback
  memo = current_user.memos.find(params[:id])

  Ai::FeedbackService.new(user: current_user).call!(memo: memo)

  redirect_to edit_memo_path(memo, anchor: "ai-feedback"), notice: "AIフィードバックを生成しました。"
rescue Ai::Generator::LimitExceeded => e
  redirect_to edit_memo_path(memo), alert: e.message
rescue OpenaiClient::TimeoutError => e
  Rails.logger.warn(e.full_message)
  redirect_to edit_memo_path(memo), alert: "AIの応答が混み合っているためタイムアウトしました。もう一度お試しください。"
rescue OpenaiClient::TemporaryError => e
  Rails.logger.warn(e.full_message)
  redirect_to edit_memo_path(memo), alert: e.message
rescue OpenaiClient::Error => e
  Rails.logger.error(e.full_message)
  redirect_to edit_memo_path(memo), alert: "AI生成に失敗しました：#{e.message}"
end

private

  # 他ユーザーのメモにアクセスできないよう current_user 経由で取得
  def set_memo
    @memo = current_user.memos.find(params[:id])
  end

  def memo_params
    params.require(:memo).permit(:symptom, :check_point, :judgment, :concern_point, :reflection, :tag_names, :status)
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

    @memos = @memos.order(created_at: :desc).distinct
    @favorite_memo_ids = current_user.favorites.pluck(:memo_id)
  end

  def apply_template_defaults(memo, template)
    memo.symptom       = memo.symptom.presence       || template.symptom_hint
    memo.check_point   = memo.check_point.presence   || template.check_point_hint
    memo.judgment      = memo.judgment.presence      || template.judgment_hint
    memo.concern_point = memo.concern_point.presence || template.concern_point_hint
    memo.reflection    = memo.reflection.presence    || template.reflection_hint

    # tag_names をフォームで使っている場合のみ（memo.tag_names がある前提）
    if memo.respond_to?(:tag_names) && memo.tag_names.blank?
      memo.tag_names = template.tag_names_hint.to_s
    end
  end
end
