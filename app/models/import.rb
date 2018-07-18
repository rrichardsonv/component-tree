class Import < ApplicationRecord
  belongs_to :code_file
  belongs_to :export
  delegate :dependent, to: :export, allow_nil: true
end