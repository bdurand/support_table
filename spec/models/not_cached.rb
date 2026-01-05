# frozen_string_literal: true

class NotCached < ApplicationRecord
  support_table cache: false
end
