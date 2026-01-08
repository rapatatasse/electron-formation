class CreateQuizAssignments < ActiveRecord::Migration[7.2]
  def change
    create_table :quiz_assignments do |t|
      t.references :quiz, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :assigned_by_type
      t.integer :assigned_by_id
      t.datetime :assigned_at
      t.datetime :due_date
      t.boolean :completed, default: false
      t.text :notes

      t.timestamps
    end

    add_index :quiz_assignments, [:quiz_id, :user_id], unique: true
    add_index :quiz_assignments, :assigned_by_id
  end
end
