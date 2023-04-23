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

ActiveRecord::Schema[7.0].define(version: 2023_04_22_143454) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "street"
    t.integer "reg_number"
    t.string "building_number"
    t.string "postal_code"
    t.bigint "legal_entity_id", null: false
    t.bigint "country_id", null: false
    t.bigint "municipality_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_addresses_on_country_id"
    t.index ["legal_entity_id"], name: "index_addresses_on_legal_entity_id"
    t.index ["municipality_id"], name: "index_addresses_on_municipality_id"
  end

  create_table "countries", force: :cascade do |t|
    t.string "codelist_code"
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "legal_entities", force: :cascade do |t|
    t.string "ico"
    t.string "dic"
    t.string "first_name"
    t.string "last_name"
    t.string "entity_name"
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "municipalities", force: :cascade do |t|
    t.string "codelist_code"
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "addresses", "countries"
  add_foreign_key "addresses", "legal_entities"
  add_foreign_key "addresses", "municipalities"
end
