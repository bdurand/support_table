# frozen_string_leteral: true

module SupportTable
  # Class to define support table behavior on an ActiveRecord class.
  #
  # @api private
  class Definition
    attr_reader :klass

    def initialize(klass)
      @klass = klass
    end

    # Setup a class to be a support table.
    #
    # @param data_file [String, Array<String>, nil] Path to data files to load the table from.
    # @param key_attribute [String, Symbol, nil] The name of the attribute in the data file that
    #   uniquely identifies each row in the data.
    # @param cache_by [String, Symbol, Array, nil] List of attributes that can be used to uniquely
    #   identify a row that can be used for caching records.
    # @param cache [ActiveSupport::Cache::Store, Symbol, Boolean, nil] The caching mechanism to use.
    # @param ttl [Numeric, ActiveSupport::Duration, nil] The time-to-live (in seconds) for cached records.
    # @return [void]
    def support_table(data_file:, key_attribute:, attribute_helpers:, cache_by:, cache:, ttl:)
      include_modules
      set_key_attribute(key_attribute)
      set_attribute_helpers(attribute_helpers)
      set_data_file(data_file)
      setup_caching(cache_by, cache, ttl)
    end

    private

    def include_modules
      klass.include SupportTableData unless klass.include?(SupportTableData)
      klass.include SupportTableCache unless klass.include?(SupportTableCache)
    end

    def set_key_attribute(key_attribute)
      klass.support_table_key_attribute = key_attribute if key_attribute
    end

    def set_attribute_helpers(attribute_helpers)
      helpers = [klass.support_table_key_attribute]
      helpers.concat(Array(attribute_helpers)) if attribute_helpers
      klass.named_instance_attribute_helpers(*helpers.uniq.compact)
    end

    def set_data_file(data_file)
      if data_file
        Array(data_file).each do |file|
          klass.add_support_table_data(file)
        end
      elsif data_file.nil?
        data_root_dir = klass.support_table_data_directory || SupportTableData.data_directory || Dir.pwd
        default_data_file = File.join(data_root_dir, "#{klass.name.pluralize.underscore}.yml")
        if File.exist?(default_data_file)
          klass.add_support_table_data(default_data_file)
        end
      end
    end

    def setup_caching(cache_by, cache, ttl)
      if cache == false
        klass.send(:cache_by, false)
        return
      end

      cache_keys = [klass.support_table_key_attribute, "id"]
      cache_keys.concat(Array(cache_by)) if cache_by
      cache_keys.uniq! { |key| Array(key).collect(&:to_s) }

      cache_keys.each do |key|
        klass.send(:cache_by, key)
      end

      klass.support_table_cache = cache
      klass.support_table_cache_ttl = ttl
    end
  end
end
