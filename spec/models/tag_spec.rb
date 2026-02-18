require "rails_helper"

RSpec.describe Tag, type: :model do
  it "有効なファクトリを持つこと" do
    expect(build(:tag)).to be_valid
  end

  it "nameが必須" do
    tag = build(:tag, name: nil)
    expect(tag).not_to be_valid
  end
end
