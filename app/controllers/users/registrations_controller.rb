class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_account_update_params, only: [:update]
  before_action :configure_sign_up_params, only: [:create]

  protected

  # 更新で許可するパラメータ（name / avatar を追加）
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :avatar])
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :avatar])
  end

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
