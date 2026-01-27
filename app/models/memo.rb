class Memo < ApplicationRecord
  belongs_to :user

  validates :symptom, :check_point, :judgment, presence: true
  has_many :memo_tags, dependent: :destroy
  has_many :tags, through: :memo_tags
  attr_accessor :tag_names

  def tag_names
    tags.pluck(:name).join(", ")
  end
end
