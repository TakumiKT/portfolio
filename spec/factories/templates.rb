FactoryBot.define do
  factory :template do
    user { nil }
    name { "MyString" }
    symptom_hint { "MyText" }
    check_point_hint { "MyText" }
    judgment_hint { "MyText" }
    concern_point_hint { "MyText" }
    reflection_hint { "MyText" }
    tag_names_hint { "MyString" }
  end
end
