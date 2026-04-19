require "rails_helper"

RSpec.describe Ai::FeedbackService, type: :service do
  describe "#call!" do
    let(:user) { create(:user) }
    let(:memo) { create(:memo, :published, user: user, symptom: "頭痛", judgment: "受診勧奨の要否を判断") }

    before do
      # タグも付けておく（tag_namesが入ることの確認用）
      tag1 = create(:tag, user: user, name: "かぜ")
      tag2 = create(:tag, user: user, name: "小児")
      create(:memo_tag, memo: memo, tag: tag2)
      create(:memo_tag, memo: memo, tag: tag1)
    end

    it "memoからmemo_hashを作り、Ai::Generatorに渡して生成する" do
      service = described_class.new(user: user)

      generator = instance_double(Ai::Generator)
      expect(Ai::Generator).to receive(:new).with(user: user, kind: "feedback", daily_limit: 3).and_return(generator)

      # generate! に渡される input_digest と memo を検証しつつ、ブロックも実行して返り値を返す
      fake_ai_result = instance_double(AiResult)

      expect(generator).to receive(:generate!) do |input_digest:, memo:, &block|
        expect(memo).to eq(memo)

        # digestは memo_hash.values.join("\n") のsha256（完全一致までやると壊れやすいので形式だけ）
        expect(input_digest).to be_a(String)
        expect(input_digest.length).to eq(64)

        # ブロックは OpenaiClient.new.feedback_for_memo(memo_hash) を呼ぶはず
        result_hash = block.call
        expect(result_hash).to include(:content, :model, :prompt_version)

        fake_ai_result
      end

      # OpenaiClient の呼び出しが「期待のmemo_hash」になっているかを見る
      openai_client = instance_double(OpenaiClient)
      expect(OpenaiClient).to receive(:new).and_return(openai_client)

      expect(openai_client).to receive(:feedback_for_memo) do |memo_hash|
        expect(memo_hash[:symptom]).to eq("頭痛")
        expect(memo_hash[:judgment]).to eq("受診勧奨の要否を判断")
        expect(memo_hash[:tag_names]).to eq("かぜ, 小児") # order(:name)なので昇順になる想定
      end.and_return({ content: "OK", model: "gpt-4.1-mini", prompt_version: "v1" })

      expect(service.call!(memo: memo)).to eq(fake_ai_result)
    end
  end
end
