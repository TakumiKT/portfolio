class AddStatusToMemos < ActiveRecord::Migration[8.1]
  def change
    add_column :memos, :status, :integer, null: false, default: 1
    add_index :memos, :status
  end
end
