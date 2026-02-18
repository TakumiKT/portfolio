FactoryBot.define do
  factory :memo do
    user
    symptom { "頭痛" }
    concern_point { "いつから/頻度/強さを確認" }
    check_point { "妊娠授乳/持病/服薬確認" }
    judgment { "受診勧奨の要否を判断" }
  end
end
