FactoryBot.define do
  factory :ai_result do
    user { nil }
    memo { nil }
    kind { "MyString" }
    input_digest { "MyString" }
    content { "MyText" }
    model { "MyString" }
    prompt_version { "MyString" }
  end
end
