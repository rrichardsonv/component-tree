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

ActiveRecord::Schema.define(version: 20180202213851) do

  create_table "code_files", force: :cascade do |t|
    t.string "file_path"
    t.string "file_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["file_name"], name: "index_code_files_on_file_name"
    t.index ["file_path"], name: "index_code_files_on_file_path"
  end

  create_table "exports", force: :cascade do |t|
    t.string "name"
    t.string "variety"
    t.string "exportable_type"
    t.integer "exportable_id"
    t.index ["exportable_type", "exportable_id"], name: "index_exports_on_exportable_type_and_exportable_id"
  end

  create_table "imports", force: :cascade do |t|
    t.string "name"
    t.integer "code_file_id"
    t.integer "export_id"
    t.index ["code_file_id"], name: "index_imports_on_code_file_id"
    t.index ["export_id"], name: "index_imports_on_export_id"
  end

  create_table "packages", force: :cascade do |t|
    t.string "path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["path"], name: "index_packages_on_path"
  end

end
