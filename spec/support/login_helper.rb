module LoginHelper
  def login_as(user, scope: :user, **_kwargs)
    sign_in(user, scope: scope)
  end
end