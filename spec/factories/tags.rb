FactoryBot.define do
  factory :tag do
    association :user
    sequence(:name) { |n| "頭痛#{n}" }
  end
end
