class AddFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :role, :integer
    add_column :users, :locale, :string
    add_column :users, :phone, :string
    add_column :users, :session, :string
    add_index :users, :session
  end
end
