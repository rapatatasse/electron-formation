class AddSessionToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :session, :string
    add_index :users, :session
  end
end
