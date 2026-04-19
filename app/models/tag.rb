class Tag < ApplicationRecord
  belongs_to :user
  has_many :memo_tags, dependent: :destroy
  has_many :memos, through: :memo_tags

  validates :name, presence: true
end
