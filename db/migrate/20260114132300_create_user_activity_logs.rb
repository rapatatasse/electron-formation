class CreateUserActivityLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :user_activity_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action_type
      t.string :resource_type
      t.integer :resource_id
      t.json :metadata
      t.string :ip_address
      t.string :user_agent
      t.datetime :performed_at

      t.timestamps
    end

    add_index :user_activity_logs, [:user_id, :performed_at]
    add_index :user_activity_logs, [:action_type, :performed_at]
    add_index :user_activity_logs, [:resource_type, :resource_id]
  end
end
