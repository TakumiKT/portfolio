FactoryBot.define do
  factory :memo_tag do
    association :memo
    association :tag
  end
end
