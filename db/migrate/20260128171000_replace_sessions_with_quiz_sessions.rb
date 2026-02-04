class ReplaceSessionsWithQuizSessions < ActiveRecord::Migration[7.2]
  def change
    if foreign_key_exists?(:user_sessions, :sessions)
      remove_foreign_key :user_sessions, :sessions
    end
    if foreign_key_exists?(:user_sessions, :users)
      remove_foreign_key :user_sessions, :users
    end

    drop_table :user_sessions, if_exists: true
    drop_table :sessions, if_exists: true

    create_table :quiz_sessions do |t|
      t.references :quiz, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :token, null: false
      t.boolean :active, default: true
      t.json :answers_data

      t.timestamps
    end

    add_index :quiz_sessions, :token, unique: true

    create_table :quiz_participants do |t|
      t.references :quiz_session, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :identifier, null: false

      t.timestamps
    end

    add_index :quiz_participants, [:quiz_session_id, :identifier], unique: true

    if column_exists?(:quiz_attempts, :user_id)
      if foreign_key_exists?(:quiz_attempts, :users)
        remove_foreign_key :quiz_attempts, :users
      end

      remove_column :quiz_attempts, :user_id
    end

    add_reference :quiz_attempts, :quiz_session, null: true, foreign_key: true
    add_reference :quiz_attempts, :quiz_participant, null: true, foreign_key: true

    if index_exists?(:quiz_attempts, [:quiz_id, :user_id])
      remove_index :quiz_attempts, column: [:quiz_id, :user_id]
    end
    if index_exists?(:quiz_attempts, :user_id)
      remove_index :quiz_attempts, :user_id
    end

    add_index :quiz_attempts, [:quiz_id, :quiz_participant_id]
  end
end
