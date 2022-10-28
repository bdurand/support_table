# frozen_string_literal: true

module SupportTable
  module BelongsToSupportTable
    extend ActiveSupport::Concern

    module ClassMethods
      def belongs_to_support_table(name, *args)
        unless include?(SupportTableCache::Associations)
          include SupportTableCache::Associations
        end

        belongs_to name, *args
        cache_belongs_to name
      end
    end
  end
end
