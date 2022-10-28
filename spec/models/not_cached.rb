# frozen_string_literal: true

class NotCached < ApplicationRecord
  include SupportTable

  support_table cache: false
end
