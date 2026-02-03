class Users::RegistrationsController < Devise::RegistrationsController
  protected

  # パスワード変更をしない更新は current_password なしで許可する
  def update_resource(resource, params)
    if params[:password].present? || params[:password_confirmation].present?
      super
    else
      params = params.except(:current_password)
      resource.update_without_password(params)
    end
  end
end