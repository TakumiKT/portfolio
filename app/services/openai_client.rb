require "timeout"

class OpenaiClient
  DEFAULT_MODEL = ENV.fetch("OPENAI_MODEL", "gpt-4.1-mini")
  PROMPT_VERSION = "v1"

  class Error < StandardError; end
  class TimeoutError < Error; end
  class TemporaryError < Error; end

  def initialize(api_key: ENV["OPENAI_API_KEY"])
    raise Error, "OPENAI_API_KEY is missing" if api_key.blank?
    @client = OpenAI::Client.new(api_key: api_key)
  end

  def feedback_for_memo(memo_hash)
    Rails.logger.warn("OPENAI_CALL feedback_for_memo")

    system = <<~SYS
      You are an assistant that helps improve a registered OTC seller's customer-service memo for learning and reflection.
      Do NOT provide medical diagnosis or definitive treatment decisions.
      Provide: (1) missing questions/checkpoints (2) risk/contraindication checks to consider (3) wording improvements (4) next action suggestions for learning.
      Keep it concise, in Japanese.
    SYS

    user = <<~USR
      以下は接客メモです。学習・振り返り用途として、改善フィードバックをください。

      【相談内容・症状】
      #{memo_hash[:symptom]}

      【確認したポイント】
      #{memo_hash[:check_point]}

      【判断・対応内容】
      #{memo_hash[:judgment]}

      【注意点・迷った点】
      #{memo_hash[:concern_point]}

      【振り返り・改善点】
      #{memo_hash[:reflection]}

      【タグ】
      #{memo_hash[:tag_names]}
    USR

    with_timeout_and_retry do
      resp = @client.chat.completions.create(
        model: DEFAULT_MODEL,
        messages: [
          { role: "system", content: system },
          { role: "user", content: user }
        ],
        temperature: 0.4,
        max_tokens: 400
      )

      text = resp.choices[0].message.content.to_s.strip
      raise Error, "Empty response from OpenAI" if text.blank?

      { content: text, model: DEFAULT_MODEL, prompt_version: PROMPT_VERSION }
    end
  end

  def report_for_memos(payload:, range_label:)
    Rails.logger.warn("OPENAI_CALL report_for_memos range_label=#{range_label.inspect}")

    system = <<~SYS
      You are an assistant that helps a registered OTC seller reflect on customer-service memos.
      Do NOT provide medical diagnosis or definitive treatment decisions.
      Output in Japanese.
    SYS

    user = <<~USR
      以下は接客メモの一覧（要約）です。対象：#{range_label}
      これをもとに「振り返りレポート」を作成してください。

      形式：
      1) 今回の概要（1〜2行）
      2) よく出た相談/症状の傾向（箇条書き）
      3) 判断で迷いが出やすいポイント（箇条書き）
      4) 次回に向けた改善アクション（3つ）
      5) タグの付け方改善案（あれば）

      データ：
      #{payload.to_json}
    USR

    with_timeout_and_retry do
      resp = @client.chat.completions.create(
        model: DEFAULT_MODEL,
        messages: [
          { role: "system", content: system },
          { role: "user", content: user }
        ],
        temperature: 0.3,
        max_tokens: 800
      )

      text = resp.choices[0].message.content.to_s.strip
      raise Error, "Empty response from OpenAI" if text.blank?

      { content: text, model: DEFAULT_MODEL, prompt_version: PROMPT_VERSION }
    end
  end

  private

  def with_timeout_and_retry(timeout_seconds: 8, retries: 2)
    attempts = 0

    begin
      attempts += 1
      Timeout.timeout(timeout_seconds) { return yield }
    rescue Timeout::Error
      raise TimeoutError, "タイムアウトしました（#{timeout_seconds}秒）" if attempts > retries
      sleep(0.6 * attempts)
      retry
    rescue OpenAI::Errors::RateLimitError
      raise TemporaryError, "混雑しています。少し時間をおいて再試行してください。"
    rescue OpenAI::Errors::ServerError
      raise TemporaryError, "OpenAI側で一時的な障害が発生しています。"
    rescue OpenAI::Errors::APIError => e
      if attempts <= retries
        sleep(0.6 * attempts)
        retry
      end
      raise Error, "APIエラー: #{e.message}"
    end
  end
end
