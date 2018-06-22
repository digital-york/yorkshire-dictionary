# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_06_14_132428) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "alt_spellings", force: :cascade do |t|
    t.string "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "definition_id"
    t.index ["definition_id"], name: "index_alt_spellings_on_definition_id"
  end

  create_table "definition_relations", force: :cascade do |t|
    t.integer "definition_id"
    t.integer "related_definition_id"
    t.string "relation_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["definition_id"], name: "index_definition_relations_on_definition_id"
    t.index ["related_definition_id"], name: "index_definition_relations_on_related_definition_id"
  end

  create_table "definition_sources", force: :cascade do |t|
    t.bigint "definition_id"
    t.bigint "source_material_id"
    t.bigint "place_id"
    t.string "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["definition_id"], name: "index_definition_sources_on_definition_id"
    t.index ["place_id"], name: "index_definition_sources_on_place_id"
    t.index ["source_material_id"], name: "index_definition_sources_on_source_material_id"
  end

  create_table "definitions", force: :cascade do |t|
    t.text "text"
    t.text "discussion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "word_id"
    t.index ["word_id"], name: "index_definitions_on_word_id"
  end

  create_table "places", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.index ["name"], name: "index_places_on_name"
  end

  create_table "places_source_references", id: false, force: :cascade do |t|
    t.bigint "source_reference_id", null: false
    t.bigint "place_id", null: false
    t.index ["place_id", "source_reference_id"], name: "index_places_source_references_on_p_id_and_sr_id"
    t.index ["source_reference_id", "place_id"], name: "index_places_source_references_on_sr_id_and_p_id"
  end

  create_table "source_dates", force: :cascade do |t|
    t.integer "start_year"
    t.integer "end_year"
    t.boolean "circa"
    t.boolean "estimate"
    t.bigint "source_reference_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_reference_id"], name: "index_source_dates_on_source_reference_id"
  end

  create_table "source_excerpts", force: :cascade do |t|
    t.bigint "source_reference_id"
    t.integer "volume_start"
    t.integer "volume_end"
    t.integer "page_start"
    t.integer "page_end"
    t.string "archival_ref"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "note"
    t.index ["source_reference_id"], name: "index_source_excerpts_on_source_reference_id"
  end

  create_table "source_materials", force: :cascade do |t|
    t.string "title"
    t.string "ref"
    t.string "original_ref"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.integer "source_type"
    t.string "archive"
    t.boolean "done"
    t.boolean "archive_checked"
  end

  create_table "source_references", force: :cascade do |t|
    t.bigint "definition_id"
    t.bigint "source_material_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["definition_id"], name: "index_source_references_on_definition_id"
    t.index ["source_material_id"], name: "index_source_references_on_source_material_id"
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
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "words", force: :cascade do |t|
    t.string "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["text"], name: "index_words_on_text"
  end

  add_foreign_key "alt_spellings", "definitions"
  add_foreign_key "definitions", "words"
  add_foreign_key "source_dates", "source_references"
  add_foreign_key "source_excerpts", "source_references"
  add_foreign_key "source_references", "definitions"
  add_foreign_key "source_references", "source_materials"
end
