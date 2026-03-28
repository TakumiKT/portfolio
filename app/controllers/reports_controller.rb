class ReportsController < ApplicationController
  before_action :authenticate_user!

  MAX_REPORT_MEMOS = 80

  def index
    # 画面に値を戻すため
    @q        = params[:q].to_s.strip
    @tag_id   = params[:tag_id].presence
    @from_date = params[:from_date].to_s.strip
    @to_date   = params[:to_date].to_s.strip
    @search_in = params[:search_in].presence || "all"      # all / symptom / judgment
    @sort      = params[:sort].presence || "newest"        # newest / oldest
    @limit     = (params[:limit].presence || "30")
    @favorites = params[:favorites].present?
    @status    = params[:status].presence || "published"   # published / drafts / both

    @selected_tag = current_user.tags.find_by(id: @tag_id) if @tag_id.present?
    @latest_report = current_user.ai_results.where(kind: "report").order(created_at: :desc).first
  end

  def generate
    q         = params[:q].to_s.strip
    tag_id    = params[:tag_id].presence
    from_date = params[:from_date].to_s.strip
    to_date   = params[:to_date].to_s.strip
    search_in = params[:search_in].presence || "all"
    sort      = params[:sort].presence || "newest"
    limit     = params[:limit].to_i
    limit     = 30 if limit <= 0
    limit     = [limit, MAX_REPORT_MEMOS].min

    favorites = params[:favorites].present?
    status    = params[:status].presence || "published" # published / drafts / both

    scope = current_user.memos.includes(:tags)

    # お気に入りのみ
    if favorites
      scope = scope.joins(:favorites).where(favorites: { user_id: current_user.id })
    end

    # 清書のみ固定
    scope = scope.published

    # 状態
    case status
    when "drafts"
      scope = scope.draft
    when "both"
      # 何もしない
    else
      scope = scope.published # デフォルトは清書
    end

    # タグ
    if tag_id.present?
      scope = scope.joins(:memo_tags).where(memo_tags: { tag_id: tag_id })
    end

    # 日付範囲（created_at）
    if from_date.present?
      from = Date.parse(from_date).beginning_of_day
      scope = scope.where("memos.created_at >= ?", from)
    end
    if to_date.present?
      to = Date.parse(to_date).end_of_day
      scope = scope.where("memos.created_at <= ?", to)
    end

    # キーワード（検索対象に応じて）
    if q.present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(q)}%"
      scope =
        case search_in
        when "symptom"
          scope.where("memos.symptom ILIKE ?", like)
        when "judgment"
          scope.where("memos.judgment ILIKE ?", like)
        else
          scope.left_joins(:tags).where(
            "memos.symptom ILIKE :q OR memos.check_point ILIKE :q OR memos.judgment ILIKE :q OR memos.concern_point ILIKE :q OR memos.reflection ILIKE :q OR tags.name ILIKE :q",
            q: like
          )
      end
    end

    scope = scope.distinct

    # 並び順
    scope =
      if sort == "oldest"
        scope.order(created_at: :asc)
      else
        scope.order(created_at: :desc)
      end

    # 期間指定がない場合は直近N件に限定
    if from_date.blank? && to_date.blank?
      scope = scope.limit(limit)
    else
      # 期間指定時も最大件数でカット（コスト暴発防止）
      scope = scope.limit(MAX_REPORT_MEMOS)
    end

    memos = scope.to_a
    if memos.empty?
      redirect_to reports_path, alert: "対象のメモがありません。条件を見直してください。"
      return
    end

    # 1日回数制限
    today = Time.zone.today
    usage = current_user.ai_usages.find_or_create_by!(date: today)
    limit_per_day = 5
    if usage.count >= limit_per_day
      redirect_to reports_path, alert: "AIレポートは1日#{limit_per_day}回までです。"
      return
    end

    # payload（短く切って送る）
    payload = memos.map do |m|
      {
        created_at: m.created_at.in_time_zone("Tokyo").strftime("%Y-%m-%d"),
        symptom: m.symptom.to_s.tr("\n", " ")[0, 140],
        judgment: m.judgment.to_s.tr("\n", " ")[0, 140],
        tags: m.tags.order(:name).pluck(:name)
      }
    end

    # 条件のラベル（レポート本文にも使う）
    cond = []
    cond << "お気に入りのみ" if favorites
    # cond << (status == "drafts" ? "下書き" : status == "both" ? "下書き+清書" : "清書")
    cond << "タグ##{current_user.tags.find_by(id: tag_id)&.name || '削除済み'}" if tag_id.present?
    cond << "q=#{q}" if q.present?
    cond << "期間#{from_date.presence || '---'}〜#{to_date.presence || '---'}" if from_date.present? || to_date.present?
    cond << (sort == "oldest" ? "古い順" : "新しい順")
    cond << "清書"
    range_label =
      if from_date.present? || to_date.present?
        cond.join(" / ")
      else
        "#{cond.join(' / ')} / 直近#{limit}件"
      end

    input_digest = Digest::SHA256.hexdigest({ payload: payload, range_label: range_label }.to_json)
    existing = current_user.ai_results.find_by(kind: "report", input_digest: input_digest)
    if existing
      redirect_to reports_path, notice: "保存済みのレポートを表示しました。"
      return
    end

    result = OpenaiClient.new.report_for_memos(payload: payload, range_label: range_label)

    current_user.ai_results.create!(
      kind: "report",
      input_digest: input_digest,
      content: result[:content],
      model: result[:model],
      prompt_version: result[:prompt_version]
    )

    usage.update!(count: usage.count + 1)

    redirect_to reports_path, notice: "AIレポートを生成しました。"
  rescue ArgumentError
    redirect_to reports_path, alert: "日付の形式が正しくありません。"
  rescue OpenaiClient::Error => e
    redirect_to reports_path, alert: "AI生成に失敗しました：#{e.message}"
  end
end