# frozen_string_literal: true

class NonStandardDataFile < ApplicationRecord
  support_table cache: false, data_file: "non_standard.yml", key_attribute: :name
end
