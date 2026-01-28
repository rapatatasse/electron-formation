# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_01_28_100003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answers", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.text "answer_text"
    t.boolean "correct"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name", limit: 150, null: false
    t.text "description"
    t.date "start_date"
    t.date "end_date"
    t.string "status", limit: 50
    t.string "manager", limit: 100
    t.bigint "creator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_projects_on_creator_id"
  end

  create_table "questions", force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.bigint "theme_id", null: false
    t.text "question_text"
    t.string "image_url"
    t.integer "difficulty_level"
    t.boolean "multiple_correct_answers"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_questions_on_quiz_id"
    t.index ["theme_id"], name: "index_questions_on_theme_id"
  end

  create_table "quiz_attempts", force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.bigint "user_id", null: false
    t.string "assigned_by_type"
    t.integer "assigned_by_id"
    t.datetime "assigned_at"
    t.datetime "due_date"
    t.text "notes"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "score"
    t.integer "initial_level"
    t.integer "final_level"
    t.integer "time_spent"
    t.boolean "passed"
    t.string "status"
    t.json "answers_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_by_id"], name: "index_quiz_attempts_on_assigned_by_id"
    t.index ["quiz_id", "user_id"], name: "index_quiz_attempts_on_quiz_id_and_user_id"
    t.index ["quiz_id"], name: "index_quiz_attempts_on_quiz_id"
    t.index ["user_id"], name: "index_quiz_attempts_on_user_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "quiz_type"
    t.integer "question_count"
    t.integer "time_limit"
    t.integer "passing_score"
    t.boolean "randomize_questions"
    t.boolean "randomize_answers"
    t.boolean "certificate_enabled"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sessions_on_name", unique: true
  end

  create_table "task_dependencies", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.bigint "dependency_task_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id", "dependency_task_id"], name: "index_task_dependencies_on_task_id_and_dependency_task_id", unique: true
    t.index ["task_id"], name: "index_task_dependencies_on_task_id"
  end

  create_table "task_users", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id", "user_id"], name: "index_task_users_on_task_id_and_user_id", unique: true
    t.index ["task_id"], name: "index_task_users_on_task_id"
    t.index ["user_id"], name: "index_task_users_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "name", limit: 150, null: false
    t.text "description"
    t.date "start_date"
    t.date "end_date"
    t.integer "duration_days"
    t.integer "hours_per_day"
    t.integer "progress", default: 0, null: false
    t.string "status", limit: 50
    t.string "priority", limit: 20
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_tasks_on_project_id"
  end

  create_table "themes", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_themes_on_name", unique: true
  end

  create_table "trainings", force: :cascade do |t|
    t.string "title", null: false
    t.decimal "price_intra_ht", precision: 10, scale: 2
    t.decimal "price_inter_ht", precision: 10, scale: 2
    t.string "training_type"
    t.string "image_url"
    t.string "duration"
    t.text "description"
    t.text "objective"
    t.text "program"
    t.text "target_audience"
    t.text "teaching_methods"
    t.text "prerequisites"
    t.integer "priority", default: 0
    t.text "evaluation_method"
    t.boolean "published", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["priority"], name: "index_trainings_on_priority"
    t.index ["published"], name: "index_trainings_on_published"
    t.index ["title"], name: "index_trainings_on_title"
  end

  create_table "user_activity_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "action_type"
    t.string "resource_type"
    t.integer "resource_id"
    t.json "metadata"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "performed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_type", "performed_at"], name: "index_user_activity_logs_on_action_type_and_performed_at"
    t.index ["resource_type", "resource_id"], name: "index_user_activity_logs_on_resource_type_and_resource_id"
    t.index ["user_id", "performed_at"], name: "index_user_activity_logs_on_user_id_and_performed_at"
    t.index ["user_id"], name: "index_user_activity_logs_on_user_id"
  end

  create_table "user_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_user_sessions_on_session_id"
    t.index ["user_id", "session_id"], name: "index_user_sessions_on_user_id_and_session_id", unique: true
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.json "role", default: ["apprenant"]
    t.string "locale"
    t.string "phone"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "answers", "questions"
  add_foreign_key "projects", "users", column: "creator_id"
  add_foreign_key "questions", "quizzes"
  add_foreign_key "questions", "themes"
  add_foreign_key "quiz_attempts", "quizzes"
  add_foreign_key "quiz_attempts", "users"
  add_foreign_key "task_dependencies", "tasks"
  add_foreign_key "task_dependencies", "tasks", column: "dependency_task_id"
  add_foreign_key "task_users", "tasks"
  add_foreign_key "task_users", "users"
  add_foreign_key "tasks", "projects"
  add_foreign_key "user_activity_logs", "users"
  add_foreign_key "user_sessions", "sessions"
  add_foreign_key "user_sessions", "users"
end
