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

ActiveRecord::Schema[8.0].define(version: 2025_08_28_043825) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "pdf_documents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "pdf_template_id"
    t.string "title"
    t.text "description"
    t.jsonb "metadata", default: {}
    t.jsonb "content_data", default: {}
    t.string "status", default: "draft"
    t.datetime "generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pdf_template_id"], name: "index_pdf_documents_on_pdf_template_id"
    t.index ["status"], name: "index_pdf_documents_on_status"
    t.index ["user_id"], name: "index_pdf_documents_on_user_id"
  end

  create_table "pdf_elements", force: :cascade do |t|
    t.bigint "pdf_document_id", null: false
    t.string "element_type"
    t.jsonb "properties", default: {}
    t.integer "page_number", default: 1
    t.float "x_position"
    t.float "y_position"
    t.float "width"
    t.float "height"
    t.integer "z_index", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pdf_document_id", "page_number"], name: "index_pdf_elements_on_pdf_document_id_and_page_number"
    t.index ["pdf_document_id"], name: "index_pdf_elements_on_pdf_document_id"
  end

  create_table "pdf_snippets", force: :cascade do |t|
    t.string "name", null: false
    t.string "snippet_type"
    t.jsonb "properties", default: {}
    t.text "content"
    t.boolean "global", default: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["global"], name: "index_pdf_snippets_on_global"
    t.index ["snippet_type"], name: "index_pdf_snippets_on_snippet_type"
    t.index ["user_id"], name: "index_pdf_snippets_on_user_id"
  end

  create_table "pdf_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "category"
    t.jsonb "structure", default: {}
    t.jsonb "default_data", default: {}
    t.string "thumbnail_url"
    t.integer "usage_count", default: 0
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_pdf_templates_on_category"
    t.index ["usage_count"], name: "index_pdf_templates_on_usage_count"
    t.index ["user_id"], name: "index_pdf_templates_on_user_id"
  end

  create_table "pdf_versions", force: :cascade do |t|
    t.bigint "pdf_document_id", null: false
    t.integer "version_number", null: false
    t.jsonb "version_changes", default: {}
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pdf_document_id", "version_number"], name: "index_pdf_versions_on_pdf_document_id_and_version_number", unique: true
    t.index ["pdf_document_id"], name: "index_pdf_versions_on_pdf_document_id"
    t.index ["user_id"], name: "index_pdf_versions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "pdf_documents", "pdf_templates"
  add_foreign_key "pdf_documents", "users"
  add_foreign_key "pdf_elements", "pdf_documents"
  add_foreign_key "pdf_snippets", "users"
  add_foreign_key "pdf_templates", "users"
  add_foreign_key "pdf_versions", "pdf_documents"
  add_foreign_key "pdf_versions", "users"
end
