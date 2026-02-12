class AddUniqueIndexesToTagsAndMemoTags < ActiveRecord::Migration[8.1]
  def change
    add_index :tags, [:user_id, :name], unique: true
    add_index :memo_tags, [:memo_id, :tag_id], unique: true
  end
end
