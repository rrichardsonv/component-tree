class CreatesPackages < ActiveRecord::Migration[5.1]
  def change
    create_table :packages do |t|
      t.string :path, index: true
      t.timestamps
    end
  end
end
