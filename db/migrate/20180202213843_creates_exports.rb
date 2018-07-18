class CreatesExports < ActiveRecord::Migration[5.1]
  def change
    create_table :exports do |t|
      t.string :name
      t.string :variety
      t.references :exportable, polymorphic: true, index: true
    end
  end
end
