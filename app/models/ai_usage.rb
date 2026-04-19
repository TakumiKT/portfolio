class AiUsage < ApplicationRecord
  belongs_to :user

  validates :date, presence: true
  validates :count, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: :date }
end
