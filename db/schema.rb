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

ActiveRecord::Schema.define(:version => 20091210233551) do

  create_table "administrations", :force => true do |t|
    t.integer  "app_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "apps", :force => true do |t|
    t.string   "name"
    t.string   "admin"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "anonymous"
    t.integer  "autoregister"
    t.boolean  "stop_subscriptions"
  end

  create_table "bj_config", :primary_key => "bj_config_id", :force => true do |t|
    t.text "hostname"
    t.text "key"
    t.text "value"
    t.text "cast"
  end

  create_table "bj_job", :primary_key => "bj_job_id", :force => true do |t|
    t.text     "command"
    t.text     "state"
    t.integer  "priority"
    t.text     "tag"
    t.integer  "is_restartable"
    t.text     "submitter"
    t.text     "runner"
    t.integer  "pid"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text     "env"
    t.text     "stdin"
    t.text     "stdout"
    t.text     "stderr"
    t.integer  "exit_status"
  end

  create_table "bj_job_archive", :primary_key => "bj_job_archive_id", :force => true do |t|
    t.text     "command"
    t.text     "state"
    t.integer  "priority"
    t.text     "tag"
    t.integer  "is_restartable"
    t.text     "submitter"
    t.text     "runner"
    t.integer  "pid"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.text     "env"
    t.text     "stdin"
    t.text     "stdout"
    t.text     "stderr"
    t.integer  "exit_status"
  end

  create_table "client_maps", :id => false, :force => true do |t|
    t.string  "client_id",       :limit => 36
    t.integer "object_value_id", :limit => 8
    t.string  "db_operation"
    t.string  "token"
    t.integer "dirty",           :limit => 1,  :default => 0
    t.integer "ack_token",       :limit => 1,  :default => 0
  end

  add_index "client_maps", ["client_id", "object_value_id"], :name => "client_map_c_id_ov_id"
  add_index "client_maps", ["client_id"], :name => "client_map_c_id"
  add_index "client_maps", ["dirty"], :name => "by_dirty"
  add_index "client_maps", ["token"], :name => "client_map_tok"

  create_table "client_temp_objects", :force => true do |t|
    t.string  "client_id"
    t.string  "objectid"
    t.string  "temp_objectid"
    t.integer "source_id"
    t.string  "token"
    t.text    "error"
  end

  create_table "clients", :id => false, :force => true do |t|
    t.string   "client_id",       :limit => 36
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "last_sync_token"
    t.string   "device_type"
    t.string   "carrier"
    t.string   "manufacturer"
    t.string   "model"
    t.string   "pin"
    t.string   "host"
    t.string   "serverport"
    t.string   "deviceport"
  end

  add_index "clients", ["client_id"], :name => "index_clients_on_client_id"

  create_table "configurations", :force => true do |t|
    t.integer  "app_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "credentials", :force => true do |t|
    t.string   "login"
    t.string   "password"
    t.string   "token"
    t.integer  "membership_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url"
  end

  create_table "memberships", :force => true do |t|
    t.integer  "app_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "object_values", :force => true do |t|
    t.integer  "source_id"
    t.string   "object"
    t.string   "attrib"
    t.text     "value"
    t.integer  "pending_id",        :limit => 8
    t.string   "update_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "blob_file_name"
    t.string   "blob_content_type"
    t.integer  "blob_file_size"
    t.string   "attrib_type"
  end

  add_index "object_values", ["object"], :name => "by_obj"
  add_index "object_values", ["source_id"], :name => "by_s"
  add_index "object_values", ["update_type"], :name => "by_ut"
  add_index "object_values", ["user_id"], :name => "by_u"

  create_table "refreshes", :force => true do |t|
    t.integer  "source_id"
    t.integer  "user_id"
    t.datetime "time"
  end

  create_table "source_logs", :force => true do |t|
    t.string   "error"
    t.string   "message"
    t.float    "timing"
    t.string   "operation"
    t.integer  "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sources", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "login"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "adapter"
    t.integer  "app_id"
    t.integer  "pollinterval"
    t.integer  "priority"
    t.integer  "incremental"
    t.boolean  "queuesync"
    t.string   "limit"
    t.string   "callback_url"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "email",                     :limit => 100
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
