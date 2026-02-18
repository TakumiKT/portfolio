module LoginHelper
  def login_as(user, password: "password")
    post user_session_path, params: { user: { email: user.email, password: "password" } }
  end
end