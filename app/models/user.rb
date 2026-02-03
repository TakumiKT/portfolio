class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable

  has_many :memos, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_one_attached :avatar
end
