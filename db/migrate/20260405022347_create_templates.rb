class CreateTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :templates do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.text :symptom_hint
      t.text :check_point_hint
      t.text :judgment_hint
      t.text :concern_point_hint
      t.text :reflection_hint
      t.string :tag_names_hint

      t.timestamps
    end
  end
end
