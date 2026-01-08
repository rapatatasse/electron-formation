class CreateCourses < ActiveRecord::Migration[7.2]
  def change
    create_table :courses do |t|
      t.string :title
      t.text :description
      t.string :slug
      t.text :content
      t.integer :position
      t.boolean :active

      t.timestamps
    end
    add_index :courses, :slug, unique: true
  end
end
