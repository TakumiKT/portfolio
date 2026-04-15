class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]
  has_many :memos, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_memos, through: :favorites, source: :memo
  has_many :ai_usages, dependent: :destroy
  has_many :ai_results, dependent: :destroy
  has_many :templates, dependent: :destroy
  has_one_attached :avatar

  def self.from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)

    user.email = auth.info.email
    user.name = auth.info.name.presence || auth.info.email.split("@").first

    # Devise用パスワード（Googleログイン時のみ内部的に設定）
    user.password = Devise.friendly_token[0, 20] if user.encrypted_password.blank?

    user.save!
    user
  end
end
