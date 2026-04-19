class CreateAiUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_usages do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date
      t.integer :count, null: false, default: 0

      t.timestamps
    end
    add_index :ai_usages, [ :user_id, :date ], unique: true
  end
end
