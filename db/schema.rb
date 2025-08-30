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

ActiveRecord::Schema[8.0].define(version: 2025_08_29_060205) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "pdf_documents", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "pdf_template_id"
    t.string "title"
    t.text "description"
    t.json "metadata", default: {}
    t.json "content_data", default: {}
    t.string "status", default: "draft"
    t.datetime "generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pdf_template_id"], name: "index_pdf_documents_on_pdf_template_id"
    t.index ["status"], name: "index_pdf_documents_on_status"
    t.index ["user_id"], name: "index_pdf_documents_on_user_id"
  end

  create_table "pdf_elements", force: :cascade do |t|
    t.integer "pdf_document_id", null: false
    t.string "element_type"
    t.json "properties", default: {}
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
    t.json "properties", default: {}
    t.text "content"
    t.boolean "global", default: false
    t.integer "user_id"
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
    t.json "structure", default: {}
    t.json "default_data", default: {}
    t.string "thumbnail_url"
    t.integer "usage_count", default: 0
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_pdf_templates_on_category"
    t.index ["usage_count"], name: "index_pdf_templates_on_usage_count"
    t.index ["user_id"], name: "index_pdf_templates_on_user_id"
  end

  create_table "pdf_versions", force: :cascade do |t|
    t.integer "pdf_document_id", null: false
    t.integer "version_number", null: false
    t.json "version_changes", default: {}
    t.integer "user_id"
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
    t.string "first_name"
    t.string "last_name"
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
