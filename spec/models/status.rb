# frozen_string_literal: true

class Status < ApplicationRecord
  include SupportTable

  belongs_to_support_table :group, class_name: "Status::Group"
end
