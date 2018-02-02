class Package < ApplicationRecord
  has_many :exports, as: :exportable
end
