class Memo < ApplicationRecord
  belongs_to :user

  validates :symptom, :check_point, :judgment, presence: true
  has_many :memo_tags, dependent: :destroy
  has_many :tags, through: :memo_tags
  has_many :favorites, dependent: :destroy
  has_many :favorited_users, through: :favorites, source: :user
  attr_accessor :tag_names
  attr_writer :tag_names
  after_save :save_tags_from_tag_names

  enum :status, { draft: 0, published: 1 }

  def tag_names
     @tag_names || tags.order(:name).pluck(:name).join(", ")
  end

  private

  def save_tags_from_tag_names
    return if @tag_names.nil?

    names = @tag_names.split(",").map(&:strip).reject(&:blank?).uniq
    new_tags = names.map do |name|
      user.tags.find_or_create_by!(name: name)
    end

    self.tags = new_tags
  end
end
