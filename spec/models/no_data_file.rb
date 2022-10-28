# frozen_string_literal: true

class NoDataFile < ApplicationRecord
  include SupportTable

  support_table data_file: false
end
