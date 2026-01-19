class CreateUserSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :session, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :user_sessions, [:user_id, :session_id], unique: true
  end
end
