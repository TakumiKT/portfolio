module Ai
  class ReportService
    MAX_REPORT_MEMOS = 80

    def initialize(user:)
      @user = user
    end

    def call!(params:)
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

      scope = build_scope(
        q: q, tag_id: tag_id, from_date: from_date, to_date: to_date,
        search_in: search_in, sort: sort, favorites: favorites, limit: limit
      )

      memos = scope.to_a
      raise ArgumentError, "対象のメモがありません" if memos.empty?

      payload = build_payload(memos)
      range_label = build_range_label(
        q: q, tag_id: tag_id, from_date: from_date, to_date: to_date,
        sort: sort, favorites: favorites, limit: limit
      )

      input_digest = Digest::SHA256.hexdigest({ payload: payload, range_label: range_label }.to_json)

      generator = Ai::Generator.new(user: @user, kind: "report", daily_limit: 3)
      generator.generate!(input_digest: input_digest, memo: nil) do
        OpenaiClient.new.report_for_memos(payload: payload, range_label: range_label)
      end
    end

    private

    def build_scope(q:, tag_id:, from_date:, to_date:, search_in:, sort:, favorites:, limit:)
      scope = @user.memos.includes(:tags)

      scope = scope.joins(:favorites).where(favorites: { user_id: @user.id }) if favorites

      # 清書のみ固定
      scope = scope.published

      if tag_id.present?
        scope = scope.joins(:memo_tags).where(memo_tags: { tag_id: tag_id })
      end

      if from_date.present?
        from = Date.parse(from_date).beginning_of_day
        scope = scope.where("memos.created_at >= ?", from)
      end
      if to_date.present?
        to = Date.parse(to_date).end_of_day
        scope = scope.where("memos.created_at <= ?", to)
      end

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
      scope = (sort == "oldest") ? scope.order(created_at: :asc) : scope.order(created_at: :desc)

      if from_date.blank? && to_date.blank?
        scope.limit(limit)
      else
        scope.limit(MAX_REPORT_MEMOS)
      end
    end

    def build_payload(memos)
      memos.map do |m|
        {
          created_at: m.created_at.in_time_zone("Tokyo").strftime("%Y-%m-%d"),
          symptom: m.symptom.to_s.tr("\n", " ")[0, 140],
          judgment: m.judgment.to_s.tr("\n", " ")[0, 140],
          tags: m.tags.order(:name).pluck(:name)
        }
      end
    end

    def build_range_label(q:, tag_id:, from_date:, to_date:, sort:, favorites:, limit:)
      cond = []
      cond << "お気に入りのみ" if favorites
      cond << "タグ##{(@user.tags.find_by(id: tag_id)&.name || '削除済み')}" if tag_id.present?
      cond << "q=#{q}" if q.present?
      cond << "期間#{from_date.presence || '---'}〜#{to_date.presence || '---'}" if from_date.present? || to_date.present?
      cond << (sort == "oldest" ? "古い順" : "新しい順")
      cond << "清書"

      if from_date.present? || to_date.present?
        cond.join(" / ")
      else
        "#{cond.join(' / ')} / 直近#{limit}件"
      end
    end
  end
end