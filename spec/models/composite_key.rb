# frozen_string_literal: true

class CompositeKey < ApplicationRecord
  support_table
  cache_by [:name, :group]
end
