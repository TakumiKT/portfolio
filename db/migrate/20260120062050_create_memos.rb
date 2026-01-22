class CreateMemos < ActiveRecord::Migration[8.1]
  def change
    create_table :memos do |t|
      t.references :user, null: false, foreign_key: true
      t.text :symptom
      t.text :check_point
      t.text :judgment
      t.text :concern_point
      t.text :reflection

      t.timestamps
    end
  end
end
