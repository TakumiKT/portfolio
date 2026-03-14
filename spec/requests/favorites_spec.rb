require "rails_helper"

RSpec.describe "Favorites", type: :request do
include LoginHelper

  let(:user) { create(:user) }
  let(:memo) { create(:memo, :published, user: user) }

  before { sign_in_as(user) }

  it "お気に入りに追加できる" do
    post memo_favorite_path(memo)
    expect(response).to redirect_to(memos_path)
    expect(user.favorites.where(memo: memo)).to exist
  end

  it "お気に入りを解除できる" do
    create(:favorite, user: user, memo: memo)
    delete memo_favorite_path(memo)
    expect(response).to redirect_to(memos_path)
    expect(user.favorites.where(memo: memo)).not_to exist
  end
end
