# frozen_string_literal: true

class Status < ApplicationRecord
  class Group < ApplicationRecord
    include SupportTable

    support_table key_attribute: :name, cache_by: :name, cache: :memory

    has_many :statuses
  end
end
