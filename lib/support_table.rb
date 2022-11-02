# frozen_string_literal: true

require "support_table_cache"
require "support_table_data"

module SupportTable
  extend ActiveSupport::Concern

  included do
    include SupportTableData unless include?(SupportTableData)
    include SupportTableCache unless include?(SupportTableCache)
    support_table
  end

  module ClassMethods
    # Define details about the support table. You only neeed to call this method if
    # you need to override any of the defaults. See SupportTableData and SupportTableCache
    # for more details.
    #
    # @param data_file [String, Array<String>] Path to the data file to use to load the table. This
    #   should be a YAML, JSON, or CSV file that defines the records that should always exist in
    #   the table. If no value is specified, then a YAML file in the data directory with the
    #   same name as the underscored, pluralized name of the class will be used. For example,
    #   if the class name is `Task::Status`, then it will look for the file `task/statuses.yml`
    #   in the `db/support_tables` directory.
    #
    # @param key_attribute [String, Symbol] The name of the attribute in the data file that
    #   uniquely identifies each row in the data. By default this will be the primary key
    #   attribute of the table (usually `id`).
    #
    # @param cache_by [String, Symbol, Array] List of attributes that can be used to uniquely
    #   identify a row that can be used for caching records. If a unique key is composite key,
    #   then
    #
    # @return [void]
    def support_table(data_file: nil, key_attribute: nil, cache_by: nil, cache: nil)
      key_attribute ||= primary_key if table_exists?
      self.support_table_key_attribute = key_attribute

      if data_file
        Array(data_file).each do |file|
          add_support_table_data(file)
        end
      elsif data_file.nil? && table_exists?
        data_root_dir = (support_table_data_directory || SupportTableData.data_directory)
        default_data_file = File.join(data_root_dir, "#{name.pluralize.underscore}.yml")
        if File.exist?(default_data_file)
          add_support_table_data(default_data_file)
        end
      end

      if table_exists?
        if cache == false
          cache_by(false)
        else
          cache_keys = [primary_key, key_attribute].compact.collect(&:to_s).uniq
          if cache_by
            cache_keys.concat(Array(cache_by))
          elsif table_exists?
            unique_keys = connection.indexes(table_name).select(&:unique).reject(&:where).collect(&:columns)
            cache_keys.concat(unique_keys)
          end
          cache_keys.uniq! { |key| Array(key).collect(&:to_s) }

          cache_keys.each do |key|
            cache_by(key)
          end

          if cache
            self.support_table_cache = cache
          end
        end
      end
    end
  end

  class << self
    # Set the directory where data files are stored. See SupportTableData for details.
    def data_directory=(dir)
      SupportTableData.data_directory = dir
    end

    # Sync all support tables. See SupportTableData for details.
    def sync_all!(*classes)
      SupportTableData.sync_all!(*classes)
    end

    # Set the cache used on support tables. See SupportTableCache for details.
    def cache=(cache_impl)
      SupportTableCache.cache = cache_impl
    end
  end
end

require_relative "support_table/belongs_to_support_table"

if defined?(ActiveRecord::Base)
  unless ActiveRecord::Base.include?(SupportTable::BelongsToSupportTable)
    ActiveRecord::Base.include(SupportTable::BelongsToSupportTable)
  end
end
