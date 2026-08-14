# frozen_string_literal: true

require "support_table_cache"
require "support_table_data"

# Include this module to add the ability to define support tables in ActiveRecord models.
# This will add the `support_table` and `belongs_to_support_table` class methods to the model.
#
# A support table is a table that contains a fixed set of data that is used to support
# the application. This data is typically loaded from a data file (YAML, JSON, or CSV)
# and is intended to be read-only. Support tables are also usually small and can be
# cached in memory for fast access.
#
# You would normally just include this module in your `ApplicationRecord` class. However,
# you can also include it in individual models.
#
# @example Define a support table
#
#   class ApplicationRecord < ActiveRecord::Base
#     self.abstract_class = true
#
#     include SupportTable
#   end
#
#   class Status < ApplicationRecord
#     support_table
#   end
#
#   class Task < ApplicationRecord
#     belongs_to_support_table :status
#   end
module SupportTable
  extend ActiveSupport::Concern

  VERSION = File.read(File.join(__dir__, "../VERSION")).strip

  included do
    include BelongsToSupportTable unless include?(BelongsToSupportTable)
  end

  module ClassMethods
    # Define details about the support table. You only need to call this method if
    # you need to override any of the defaults. See SupportTableData and SupportTableCache
    # for more details.
    #
    # @param data_file [String, Array<String>, false, nil] Path to the data file to use to load the table. This
    #   should be a YAML, JSON, or CSV file that defines the records that should always exist in
    #   the table. If no value is specified, then a YAML file in the data directory with the
    #   same name as the underscored, pluralized name of the class will be used. For example,
    #   if the class name is `Task::Status`, then it will look for the file `task/statuses.yml`
    #   in the `db/support_tables` directory. You can pass `false` to disable loading the
    #   default data file.
    #
    # @param key_attribute [String, Symbol, nil] The name of the attribute in the data file that
    #   uniquely identifies each row in the data. By default this will be the `id` attribute.
    #
    # @param attribute_helpers [String, Symbol, Array<String, Symbol>, nil] List of attributes
    #   which should have helper methods created for them. This generates methods for each named instance
    #   to get that attribute directly from the YAML data. For example, adding a helper for `:name`
    #   will create a class method `*_name` for each named instance (i.e. Status.draft_name).
    #
    # @param cache_by [String, Symbol, Array, nil] List of attributes that can be used to uniquely
    #   identify a row that can be used for caching records. If a unique key is made up of
    #   multiple columns, then you will need to set it up with a call to `SupportTableCache.cache_by`
    #
    # @param cache [ActiveSupport::Cache::Store, Symbol, Boolean, nil] The caching mechanism to use.
    #   This can be either an instance of `ActiveSupport::Cache::Store` like `Rails.cache`, or
    #   the value `:memory` to use an in-memory cache, or `false` or `nil` to disable caching.
    #
    # @param ttl [Numeric, ActiveSupport::Duration, nil] The time-to-live (in seconds) for cached
    #   records. If not specified, cached records never expire.
    #
    # @return [void]
    def support_table(data_file: nil, key_attribute: nil, attribute_helpers: nil, cache_by: nil, cache: :memory, ttl: nil)
      SupportTable::Definition.new(self).support_table(
        data_file: data_file,
        key_attribute: key_attribute,
        attribute_helpers: attribute_helpers,
        cache_by: cache_by,
        cache: cache,
        ttl: ttl
      )
    end
  end

  class << self
    # Set the directory where data files are stored. See SupportTableData for details.
    # This is an alias for `SupportTableData.data_directory=`.
    #
    # @param dir [String] Path to the directory where data files are stored.
    # @return [void]
    def data_directory=(dir)
      SupportTableData.data_directory = dir
    end

    # Sync all support tables. See SupportTableData for details. This is an alias for
    # `SupportTableData.sync_all!`.
    #
    # @param classes [Array<Class>] List of support table classes to sync. If no classes
    #   are specified, then all support tables will be synced.
    # @return [void]
    def sync_all!(*classes)
      SupportTableData.sync_all!(*classes)
    end

    # Set the cache used on support tables. See SupportTableCache for details. This is an
    # alias for `SupportTableCache.cache=`.
    #
    # @param cache_impl [ActiveSupport::Cache::Store] The cache implementation to use.
    # @return [void]
    def cache=(cache_impl)
      SupportTableCache.cache = cache_impl
    end
  end
end

require_relative "support_table/belongs_to_support_table"
require_relative "support_table/definition"
