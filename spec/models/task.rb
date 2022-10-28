# frozen_string_literal: true

class Task < ApplicationRecord
  belongs_to_support_table :status
end
