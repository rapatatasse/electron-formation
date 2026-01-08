class CreateQuizStatistics < ActiveRecord::Migration[7.2]
  def change
    create_table :quiz_statistics do |t|
      t.references :quiz, null: false, foreign_key: true
      t.integer :total_attempts
      t.integer :total_completions
      t.float :average_score
      t.float :average_time
      t.integer :pass_count
      t.integer :fail_count
      t.float :pass_rate
      t.datetime :last_calculated_at

      t.timestamps
    end
  end
end
