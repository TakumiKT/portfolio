# 認証必須＆CRUD（memos）
require "rails_helper"

RSpec.describe Memo, type: :model do
  it "有効なファクトリを持つこと" do
    expect(build(:memo)).to be_valid
  end

  it "userが必須" do
    memo = build(:memo, user: nil)
    expect(memo).not_to be_valid
  end

  it "symptomが必須" do
    memo = build(:memo, symptom: nil)
    expect(memo).not_to be_valid
  end
end