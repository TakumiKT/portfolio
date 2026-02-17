FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "頭痛#{n}" }
  end
end