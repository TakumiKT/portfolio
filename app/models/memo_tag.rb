class MemoTag < ApplicationRecord
  belongs_to :memo
  belongs_to :tag
end
