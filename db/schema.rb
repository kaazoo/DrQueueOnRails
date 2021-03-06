# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110507205238) do

  create_table "jobs", :force => true do |t|
    t.string  "renderer"
    t.string  "sort"
    t.integer "profile_id"
    t.string  "queue_id"
  end

  create_table "payments", :force => true do |t|
    t.integer  "profile_id"
    t.date     "paid_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "amount"
  end

  create_table "profiles", :force => true do |t|
    t.string  "name"
    t.string  "email"
    t.string  "avatar"
    t.string  "ldap_account"
    t.string  "status"
    t.integer "accepted",     :default => 0
  end

  create_table "rendersessions", :force => true do |t|
    t.integer  "num_slaves"
    t.integer  "run_time"
    t.integer  "payment_id"
    t.integer  "time_passed",         :default => 0
    t.integer  "start_timestamp",     :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "stop_timestamp",      :default => 0
    t.integer  "overall_time_passed", :default => 0
    t.string   "vm_type",             :default => "t1.micro"
    t.integer  "profile_id"
    t.float    "costs"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"

end
