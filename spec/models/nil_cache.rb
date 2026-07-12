# frozen_string_literal: true

class NilCache < ApplicationRecord
  self.table_name = "not_cacheds"

  support_table cache: nil, data_file: false
end
