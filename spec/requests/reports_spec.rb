require "rails_helper"

RSpec.describe "Reports", type: :request do
  let(:user) { create(:user) }

  before { sign_in_as(user) }
  describe "GET /reports" do
    it "returns http success" do
      get reports_path
      expect(response).to have_http_status(:success)
    end
  end
end
