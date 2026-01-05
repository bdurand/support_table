# frozen_string_literal: true

require "bundler/setup"

require "logger"
require "active_record"

ActiveRecord::Base.establish_connection("adapter" => "sqlite3", "database" => ":memory:")

require_relative "../lib/support_table"

SupportTable.data_directory = File.join(__dir__, "data")

SupportTable.cache = ActiveSupport::Cache::MemoryStore.new

ActiveRecord::Base.connection.tap do |connection|
  connection.create_table(:status_groups) do |t|
    t.string :name, null: false
    t.string :description, null: false
    t.timestamps
  end

  connection.create_table(:statuses) do |t|
    t.string :name, null: false, index: {unique: true}
    t.references :status_group
    t.timestamps
  end

  connection.create_table(:tasks) do |t|
    t.string :description, null: false
    t.references :status
  end

  connection.create_table(:not_cacheds) do |t|
    t.string :name, null: false, index: {unique: true}
  end

  connection.create_table(:no_data_files) do |t|
    t.string :name, null: false, index: {unique: true}
  end

  connection.create_table(:non_standard_data_files) do |t|
    t.string :name, null: false, index: {unique: true}
  end

  connection.create_table(:deletable_items) do |t|
    t.string :name, null: false, index: {unique: true, where: "deleted_at IS NULL"}
    t.datetime :deleted_at
  end
end

Dir.chdir(File.expand_path(__dir__)) do
  Dir.glob("models/*.rb").each do |file|
    class_name = file.sub("models/", "").sub(".rb", "").classify
    autoload class_name.to_sym, File.expand_path(file, __dir__)
  end

  require_relative "models/status/group"
end

RSpec.configure do |config|
  config.order = :random

  config.before(:suite) do
    SupportTable.sync_all!
  end
end
