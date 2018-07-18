class Export < ApplicationRecord
  has_many :imports
  belongs_to :exportable

  delegate :path, to: :exportable

  def dependent
    self.exportable
  end
end