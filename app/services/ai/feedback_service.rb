module Ai
  class FeedbackService
    def initialize(user:)
      @user = user
    end

    def call!(memo:)
      memo_hash = build_memo_hash(memo)
      input_digest = Digest::SHA256.hexdigest(memo_hash.values.join("\n"))

      generator = Ai::Generator.new(user: @user, kind: "feedback", daily_limit: 3)

      generator.generate!(input_digest: input_digest, memo: memo) do
        OpenaiClient.new.feedback_for_memo(memo_hash)
      end
    end

    private

    def build_memo_hash(memo)
      {
        symptom: memo.symptom.to_s,
        check_point: memo.check_point.to_s,
        judgment: memo.judgment.to_s,
        concern_point: memo.concern_point.to_s,
        reflection: memo.reflection.to_s,
        tag_names: memo.tags.order(:name).pluck(:name).join(", ")
      }
    end
  end
end