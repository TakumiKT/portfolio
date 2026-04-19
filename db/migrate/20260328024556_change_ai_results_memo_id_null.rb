class ChangeAiResultsMemoIdNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :ai_results, :memo_id, true
  end
end
