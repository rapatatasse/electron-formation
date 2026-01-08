# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.

ActiveRecord::Schema[7.0].define(version: 2026_01_08_000000) do

  # ============================================================================
  # USERS & AUTHENTICATION
  # ============================================================================
  
  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "role", default: 0, null: false # 0: apprenant, 1: formateur, 2: admin
    t.string "locale", default: "fr" # Pour le multilingue
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.timestamps
    
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  # ============================================================================
  # COURSES (Pages statiques)
  # ============================================================================
  
  create_table "courses", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "slug", null: false
    t.text "content" # Contenu statique de la page
    t.integer "position", default: 0 # Pour l'ordre d'affichage
    t.boolean "active", default: true
    t.timestamps
    
    t.index ["slug"], name: "index_courses_on_slug", unique: true
    t.index ["position"], name: "index_courses_on_position"
  end

  # ============================================================================
  # COURSE ASSIGNMENTS (Attribution cours ↔ formateurs/apprenants)
  # ============================================================================
  
  create_table "course_assignments", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.bigint "user_id", null: false
    t.string "assignment_type", null: false # 'formateur' ou 'apprenant'
    t.datetime "assigned_at"
    t.timestamps
    
    t.index ["course_id"], name: "index_course_assignments_on_course_id"
    t.index ["user_id"], name: "index_course_assignments_on_user_id"
    t.index ["course_id", "user_id", "assignment_type"], name: "index_course_user_assignment", unique: true
  end

  # ============================================================================
  # THEMES (Catégories de questions)
  # ============================================================================
  
  create_table "themes", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "color" # Pour l'affichage visuel
    t.timestamps
    
    t.index ["name"], name: "index_themes_on_name", unique: true
  end

  # ============================================================================
  # QUIZZES
  # ============================================================================
  
  create_table "quizzes", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.bigint "creator_id", null: false # Formateur qui a créé le quiz
    t.bigint "course_id" # Quiz peut être lié à un cours (optionnel)
    t.integer "quiz_type", default: 0, null: false # 0: simple, 1: adaptatif
    t.integer "question_count" # Nombre de questions pour le quiz
    t.integer "time_limit" # Temps limite en minutes (null = pas de limite)
    t.integer "passing_threshold", default: 50 # Seuil de validation (0-100)
    t.boolean "randomize_questions", default: false
    t.boolean "randomize_answers", default: false
    t.boolean "certificate_enabled", default: false
    t.boolean "active", default: true
    t.timestamps
    
    t.index ["creator_id"], name: "index_quizzes_on_creator_id"
    t.index ["course_id"], name: "index_quizzes_on_course_id"
    t.index ["quiz_type"], name: "index_quizzes_on_quiz_type"
  end

  # ============================================================================
  # QUESTIONS
  # ============================================================================
  
  create_table "questions", force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.bigint "theme_id", null: false
    t.text "question_text", null: false
    t.string "image_url" # Lien vers l'image
    t.integer "difficulty_level", default: 50, null: false # 0-100
    t.boolean "randomize_answers", default: false # Ordre aléatoire des réponses
    t.boolean "multiple_correct_answers", default: false # Permet plusieurs réponses correctes (QCM multiple)
    t.integer "position" # Ordre dans le quiz (pour quiz simple)
    t.timestamps
    
    t.index ["quiz_id"], name: "index_questions_on_quiz_id"
    t.index ["theme_id"], name: "index_questions_on_theme_id"
    t.index ["difficulty_level"], name: "index_questions_on_difficulty_level"
  end

  # ============================================================================
  # ANSWERS (Réponses possibles pour chaque question)
  # ============================================================================
  
  create_table "answers", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.text "answer_text", null: false
    t.boolean "is_correct", default: false, null: false
    t.integer "position" # Pour l'ordre d'affichage
    t.timestamps
    
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  # ============================================================================
  # QUIZ ATTEMPTS (Sessions de passage de quiz)
  # ============================================================================
  
  create_table "quiz_attempts", force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.bigint "user_id", null: false # Apprenant
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "score" # Score final (0-100)
    t.integer "initial_level", default: 50 # Niveau de départ (pour adaptatif)
    t.integer "final_level" # Niveau final atteint (pour adaptatif)
    t.integer "correct_answers_count", default: 0
    t.integer "total_questions", default: 0
    t.integer "time_spent" # Temps passé en secondes
    t.boolean "passed", default: false # A validé le seuil ou non
    t.string "status", default: "in_progress" # in_progress, completed, abandoned
    t.timestamps
    
    t.index ["quiz_id"], name: "index_quiz_attempts_on_quiz_id"
    t.index ["user_id"], name: "index_quiz_attempts_on_user_id"
    t.index ["completed_at"], name: "index_quiz_attempts_on_completed_at"
    t.index ["status"], name: "index_quiz_attempts_on_status"
  end

  # ============================================================================
  # ATTEMPT ANSWERS (Réponses données lors d'une session)
  # ============================================================================
  
  create_table "attempt_answers", force: :cascade do |t|
    t.bigint "quiz_attempt_id", null: false
    t.bigint "question_id", null: false
    t.bigint "answer_id" # Réponse choisie (null si pas répondu) - pour question simple
    t.json "answer_ids" # Array des réponses choisies - pour questions à réponses multiples
    t.boolean "is_correct"
    t.integer "question_difficulty" # Difficulté de la question au moment de la réponse
    t.integer "user_level_at_time" # Niveau de l'utilisateur à ce moment (adaptatif)
    t.integer "time_spent" # Temps passé sur cette question en secondes
    t.integer "position" # Ordre de la question dans la session
    t.timestamps
    
    t.index ["quiz_attempt_id"], name: "index_attempt_answers_on_quiz_attempt_id"
    t.index ["question_id"], name: "index_attempt_answers_on_question_id"
    t.index ["answer_id"], name: "index_attempt_answers_on_answer_id"
  end

 




  # ============================================================================
  # FOREIGN KEYS
  # ============================================================================
  
  add_foreign_key "course_assignments", "courses"
  add_foreign_key "course_assignments", "users"
  add_foreign_key "quizzes", "users", column: "creator_id"
  add_foreign_key "quizzes", "courses"
  add_foreign_key "questions", "quizzes"
  add_foreign_key "questions", "themes"
  add_foreign_key "answers", "questions"
  add_foreign_key "quiz_attempts", "quizzes"
  add_foreign_key "quiz_attempts", "users"
  add_foreign_key "attempt_answers", "quiz_attempts"
  add_foreign_key "attempt_answers", "questions"
  add_foreign_key "attempt_answers", "answers"

end
