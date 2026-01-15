class CreateQuizAttempts < ActiveRecord::Migration[7.2]
  def change
    create_table :quiz_attempts do |t|
      t.references :quiz, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      
      # Champs d'assignation
      t.string :assigned_by_type
      t.integer :assigned_by_id
      t.datetime :assigned_at
      t.datetime :due_date
      t.text :notes
      
      # Champs de tentative
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :score
      t.integer :initial_level
      t.integer :final_level
      t.integer :time_spent
      t.boolean :passed
      t.string :status
      
      # Stockage des réponses en JSON
      # Format: [{ question_id: 1, question_text: "...", question_updated_at: "...", 
      #            answer_ids: [1,2], answers: [{id: 1, text: "...", correct: true, updated_at: "..."}], 
      #            correct: true, position: 1 }]
      t.json :answers_data

      t.timestamps
    end
    
    add_index :quiz_attempts, [:quiz_id, :user_id]
    add_index :quiz_attempts, :assigned_by_id
  end
end
