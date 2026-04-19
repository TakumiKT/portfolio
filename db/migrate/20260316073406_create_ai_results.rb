class CreateAiResults < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_results do |t|
      t.references :user, null: false, foreign_key: true
      t.references :memo, null: false, foreign_key: true
      t.string :kind
      t.string :input_digest
      t.text :content
      t.string :model
      t.string :prompt_version

      t.timestamps
    end
    add_index :ai_results, [ :user_id, :kind, :input_digest ]
  end
end
