class AddKindToAiUsages < ActiveRecord::Migration[8.1]
  def change
    add_column :ai_usages, :kind, :string, null: false, default: "feedback"
    add_index :ai_usages, [:user_id, :date, :kind], unique: true
  end
end
