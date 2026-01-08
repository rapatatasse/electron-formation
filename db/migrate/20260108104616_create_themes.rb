class CreateThemes < ActiveRecord::Migration[7.2]
  def change
    create_table :themes do |t|
      t.string :name
      t.text :description
      t.string :color

      t.timestamps
    end
    add_index :themes, :name, unique: true
  end
end
