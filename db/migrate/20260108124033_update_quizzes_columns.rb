class UpdateQuizzesColumns < ActiveRecord::Migration[7.2]
  def change
    # Supprimer l'ancienne clé étrangère incorrecte
    remove_foreign_key :quizzes, column: :creator_id if foreign_key_exists?(:quizzes, column: :creator_id)
    
    # Renommer passing_threshold en passing_score
    rename_column :quizzes, :passing_threshold, :passing_score
    
    # Ajouter la colonne max_attempts
    add_column :quizzes, :max_attempts, :integer
    
    # Rendre course_id optionnel (nullable)
    change_column_null :quizzes, :course_id, true
    
    # Ajouter la bonne clé étrangère vers users
    add_foreign_key :quizzes, :users, column: :creator_id
  end
end