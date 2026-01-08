class CreateQuizAttempts < ActiveRecord::Migration[7.2]
  def change
    create_table :quiz_attempts do |t|
      t.references :quiz, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :score
      t.integer :initial_level
      t.integer :final_level
      t.integer :correct_answers_count
      t.integer :total_questions
      t.integer :time_spent
      t.boolean :passed
      t.string :status

      t.timestamps
    end
  end
end
