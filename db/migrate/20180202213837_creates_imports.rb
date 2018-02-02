class CreatesImports < ActiveRecord::Migration[5.1]
  def change
    create_table :imports do |t|
      t.string :name
      t.references :code_file, index: true
      t.references :export, index: true
      t.timestamp
    end
  end
end
