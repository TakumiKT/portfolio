FactoryBot.define do
  factory :memo do
    user
    symptom { "頭痛" }
    concern_point { "いつから/頻度/強さを確認" }
    check_point { "妊娠授乳/持病/服薬確認" }
    judgement { "受診勧奨の要否を判断" }
    suggestion { "水分摂取・休養、必要なら受診" }
  end
end
