class ReportsController < ApplicationController
  before_action :authenticate_user!

  MAX_REPORT_MEMOS = 80

  def index
    # 画面に値を戻す
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
    Ai::ReportService.new(user: current_user).call!(params: params)
    redirect_to reports_path, notice: "AIレポートを生成しました。"
  rescue Ai::Generator::LimitExceeded => e
    redirect_to reports_path, alert: e.message
  rescue ArgumentError
    redirect_to reports_path, alert: "日付の形式が正しくありません。"
  rescue OpenaiClient::Error => e
    redirect_to reports_path, alert: "AI生成に失敗しました：#{e.message}"
  end
end
