class Export < ApplicationRecord
  has_many :imports
  belongs_to :exportable

  alias_attribute :exportable, :dependent
end