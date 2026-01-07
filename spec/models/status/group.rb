# frozen_string_literal: true

class Status::Group < ApplicationRecord
  support_table key_attribute: :name, attribute_helpers: :description, cache_by: :code, ttl: 1.minute

  has_many :statuses
end
