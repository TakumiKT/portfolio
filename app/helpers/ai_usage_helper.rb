module AiUsageHelper
  FEEDBACK_LIMIT = 3
  REPORT_LIMIT   = 3 # あなたのReportServiceに合わせて

  def ai_remaining(kind)
    today = Time.zone.today
    used = current_user.ai_usages.find_by(date: today, kind: kind)&.count.to_i

    limit =
      case kind.to_s
      when "feedback" then FEEDBACK_LIMIT
      when "report"   then REPORT_LIMIT
      else 0
      end

    remaining = limit - used
    remaining < 0 ? 0 : remaining
  end

  def ai_used(kind)
    current_user.ai_usages.find_by(date: Time.zone.today, kind: kind)&.count.to_i
  end
end
