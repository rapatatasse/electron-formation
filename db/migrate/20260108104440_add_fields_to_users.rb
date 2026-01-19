class AddFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :role, :json, default: ['apprenant']
    add_column :users, :locale, :string
    add_column :users, :phone, :string
  end
end
