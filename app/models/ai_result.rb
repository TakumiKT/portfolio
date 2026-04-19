class AiResult < ApplicationRecord
  belongs_to :user
  belongs_to :memo, optional: true

  validates :kind, presence: true
  validates :input_digest, presence: true
  validates :content, presence: true
  validates :memo_id, presence: true, if: -> { kind == "feedback" }
end
