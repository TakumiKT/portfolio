class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :memo
  validate :memo_belongs_to_user

  def memo_belongs_to_user
    return if memo.nil? || user.nil?
    errors.add(:memo, "は自分のメモのみお気に入りできます") if memo.user_id != user.id
  end
end
