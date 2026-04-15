module Ai
  class Generator
    class LimitExceeded < StandardError; end

    def initialize(user:, kind:, daily_limit:)
      @user = user
      @kind = kind # "feedback" / "report"
      @daily_limit = daily_limit
    end

    # memo: feedbackはMemoを渡す、reportはnilでOK
    def generate!(input_digest:, memo: nil)
      enforce_daily_limit!

      existing = find_existing(input_digest, memo)
      return existing if existing

      result_hash = yield # => {content:, model:, prompt_version:}

      ai_result = @user.ai_results.create!(
        memo: memo,
        kind: @kind,
        input_digest: input_digest,
        content: result_hash.fetch(:content),
        model: result_hash.fetch(:model),
        prompt_version: result_hash.fetch(:prompt_version)
      )

      increment_usage!
      ai_result
    end

    private

    def enforce_daily_limit!
      usage = @user.ai_usages.find_or_create_by!(date: Time.zone.today, kind: @kind)
      raise LimitExceeded, "AIは1日#{@daily_limit}回までです。" if usage.count >= @daily_limit
    end

    def increment_usage!
      usage = @user.ai_usages.find_or_create_by!(date: Time.zone.today, kind: @kind)
      sage.update!(count: usage.count + 1)
    end

    def find_existing(input_digest, memo)
      @user.ai_results.find_by(kind: @kind, input_digest: input_digest, memo_id: memo&.id)
    end
  end
end
