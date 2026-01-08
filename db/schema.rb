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

ActiveRecord::Schema[7.2].define(version: 2026_01_08_154700) do
  create_table "answers", force: :cascade do |t|
    t.integer "question_id", null: false
    t.text "answer_text"
    t.boolean "is_correct"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "attempt_answers", force: :cascade do |t|
    t.integer "quiz_attempt_id", null: false
    t.integer "question_id", null: false
    t.json "answer_ids", null: false
    t.boolean "correct"
    t.integer "question_difficulty"
    t.integer "user_level_at_time"
    t.integer "time_spent"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_attempt_answers_on_question_id"
    t.index ["quiz_attempt_id"], name: "index_attempt_answers_on_quiz_attempt_id"
  end

  create_table "certificates", force: :cascade do |t|
    t.integer "quiz_attempt_id", null: false
    t.integer "user_id", null: false
    t.integer "issued_by_id", null: false
    t.string "certificate_number"
    t.integer "score"
    t.string "level"
    t.string "pdf_url"
    t.datetime "issued_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["certificate_number"], name: "index_certificates_on_certificate_number", unique: true
    t.index ["issued_by_id"], name: "index_certificates_on_issued_by_id"
    t.index ["quiz_attempt_id"], name: "index_certificates_on_quiz_attempt_id"
    t.index ["user_id"], name: "index_certificates_on_user_id"
  end

  create_table "course_assignments", force: :cascade do |t|
    t.integer "course_id", null: false
    t.integer "user_id", null: false
    t.string "assignment_type"
    t.datetime "assigned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_assignments_on_course_id"
    t.index ["user_id"], name: "index_course_assignments_on_user_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "slug"
    t.text "content"
    t.integer "position"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_courses_on_slug", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.integer "quiz_id", null: false
    t.integer "theme_id", null: false
    t.text "question_text"
    t.string "image_url"
    t.integer "difficulty_level"
    t.boolean "randomize_answers"
    t.boolean "multiple_correct_answers"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_questions_on_quiz_id"
    t.index ["theme_id"], name: "index_questions_on_theme_id"
  end

  create_table "quiz_assignments", force: :cascade do |t|
    t.integer "quiz_id", null: false
    t.integer "user_id", null: false
    t.string "assigned_by_type"
    t.integer "assigned_by_id"
    t.datetime "assigned_at"
    t.datetime "due_date"
    t.boolean "completed", default: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_by_id"], name: "index_quiz_assignments_on_assigned_by_id"
    t.index ["quiz_id", "user_id"], name: "index_quiz_assignments_on_quiz_id_and_user_id", unique: true
    t.index ["quiz_id"], name: "index_quiz_assignments_on_quiz_id"
    t.index ["user_id"], name: "index_quiz_assignments_on_user_id"
  end

  create_table "quiz_attempts", force: :cascade do |t|
    t.integer "quiz_id", null: false
    t.integer "user_id", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "score"
    t.integer "initial_level"
    t.integer "final_level"
    t.integer "correct_answers_count"
    t.integer "total_questions"
    t.integer "time_spent"
    t.boolean "passed"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_quiz_attempts_on_quiz_id"
    t.index ["user_id"], name: "index_quiz_attempts_on_user_id"
  end

  create_table "quiz_statistics", force: :cascade do |t|
    t.integer "quiz_id", null: false
    t.integer "total_attempts"
    t.integer "total_completions"
    t.float "average_score"
    t.float "average_time"
    t.integer "pass_count"
    t.integer "fail_count"
    t.float "pass_rate"
    t.datetime "last_calculated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_quiz_statistics_on_quiz_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "creator_id", null: false
    t.integer "course_id"
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
    t.integer "max_attempts"
    t.index ["course_id"], name: "index_quizzes_on_course_id"
    t.index ["creator_id"], name: "index_quizzes_on_creator_id"
  end

  create_table "theme_statistics", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "theme_id", null: false
    t.integer "questions_answered"
    t.integer "correct_answers"
    t.float "success_rate"
    t.float "average_difficulty"
    t.datetime "last_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["theme_id"], name: "index_theme_statistics_on_theme_id"
    t.index ["user_id"], name: "index_theme_statistics_on_user_id"
  end

  create_table "themes", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_themes_on_name", unique: true
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
    t.integer "role"
    t.string "locale"
    t.string "phone"
    t.string "session"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["session"], name: "index_users_on_session"
  end

  add_foreign_key "answers", "questions"
  add_foreign_key "attempt_answers", "questions"
  add_foreign_key "attempt_answers", "quiz_attempts"
  add_foreign_key "certificates", "issued_bies"
  add_foreign_key "certificates", "quiz_attempts"
  add_foreign_key "certificates", "users"
  add_foreign_key "course_assignments", "courses"
  add_foreign_key "course_assignments", "users"
  add_foreign_key "questions", "quizzes"
  add_foreign_key "questions", "themes"
  add_foreign_key "quiz_assignments", "quizzes"
  add_foreign_key "quiz_assignments", "users"
  add_foreign_key "quiz_attempts", "quizzes"
  add_foreign_key "quiz_attempts", "users"
  add_foreign_key "quiz_statistics", "quizzes"
  add_foreign_key "quizzes", "courses"
  add_foreign_key "quizzes", "users", column: "creator_id"
  add_foreign_key "theme_statistics", "themes"
  add_foreign_key "theme_statistics", "users"
end
