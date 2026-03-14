FactoryBot.define do
  factory :memo do
    association :user
    symptom { "頭痛" }
    check_point { "妊娠授乳/持病/服薬確認" }
    judgment { "受診勧奨の要否を判断" }
    concern_point { "いつから/頻度/強さを確認" }
    reflection { "次回は併用薬をより詳細に確認" }

    trait :draft do
      status { :draft }
    end

    trait :published do
      status { :published }
    end
  end
end
