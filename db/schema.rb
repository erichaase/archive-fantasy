# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120627214339) do

  create_table "box_score_entries", :force => true do |t|
    t.integer  "pid_espn"
    t.string   "fname"
    t.string   "lname"
    t.integer  "min"
    t.integer  "fgm"
    t.integer  "fga"
    t.integer  "tpm"
    t.integer  "tpa"
    t.integer  "ftm"
    t.integer  "fta"
    t.integer  "oreb"
    t.integer  "reb"
    t.integer  "ast"
    t.integer  "stl"
    t.integer  "blk"
    t.integer  "to"
    t.integer  "pf"
    t.integer  "plusminus"
    t.integer  "pts"
    t.string   "status"
    t.integer  "box_score_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "box_score_entries", ["box_score_id"], :name => "box_score_id_ix"
  add_index "box_score_entries", ["pid_espn"], :name => "pid_espn_ix"

  create_table "box_scores", :force => true do |t|
    t.integer  "gid_espn"
    t.string   "status"
    t.date     "date"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "box_scores", ["date"], :name => "date_ix"
  add_index "box_scores", ["gid_espn"], :name => "gid_espn_ix", :unique => true

end
