class CreatesPackages < ActiveRecord::Migration[5.1]
  def change
    create_table :packages do |t|
      t.string :file_path, index: true
      t.string :file_name, index: true
      t.timestamps
    end
  end
end
