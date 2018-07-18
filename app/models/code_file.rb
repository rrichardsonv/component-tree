class CodeFile < ApplicationRecord
  has_many :imports
  has_many :exports, as: :exportable
  has_many :dependencies, through: :imports

  def dependencies
    imports.collect(&:dependent)
  end
end