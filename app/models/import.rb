class Import < ApplicationRecord
  belongs_to :code_file
  belongs_to :export
  delegates :dependent, to: :export, allow_nil: true
end