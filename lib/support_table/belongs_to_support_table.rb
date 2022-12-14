# frozen_string_literal: true

module SupportTable
  module BelongsToSupportTable
    extend ActiveSupport::Concern

    module ClassMethods
      def belongs_to_support_table(name, *args, **kwargs)
        unless include?(SupportTableCache::Associations)
          include SupportTableCache::Associations
        end

        belongs_to name, *args, **kwargs
        cache_belongs_to name
      end
    end
  end
end
