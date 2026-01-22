class Memo < ApplicationRecord
  belongs_to :user

  validates :symptom, :check_point, :judgment, presence: true
end