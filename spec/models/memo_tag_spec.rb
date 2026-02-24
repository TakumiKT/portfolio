require "rails_helper"

RSpec.describe MemoTag, type: :model do
  it "memoとtagを紐付けできる" do
    expect(build(:memo_tag)).to be_valid
  end
end
