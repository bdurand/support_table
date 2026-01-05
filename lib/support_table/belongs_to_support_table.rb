# frozen_string_literal: true

module SupportTable
  # Module to add support for specifying `belongs_to` associations that
  # reference support tables.
  module BelongsToSupportTable
    extend ActiveSupport::Concern

    module ClassMethods
      # Define a `belongs_to` association that references a support table. This method takes
      # the same arguments as `belongs_to`. It will add a caching layer to the association
      # to minimize database queries.
      #
      # @param name [Symbol] The name of the association.
      # @param args [Array] Additional arguments to pass to `belongs_to`.
      # @param kwargs [Hash] Additional keyword arguments to pass to `belongs_to`.
      # @return [void]
      def belongs_to_support_table(name, *args, **kwargs)
        unless include?(SupportTableCache::Associations)
          include SupportTableCache::Associations
        end

        retval = belongs_to name, *args, **kwargs
        cache_belongs_to name
        retval
      end
    end
  end
end
