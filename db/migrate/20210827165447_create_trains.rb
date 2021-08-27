class CreateTrains < ActiveRecord::Migration[6.1]
  def change
    create_table :trains do |t|
      t.references :user, foreign_key: :true
      t.string :url
      t.timestamps
    end
  end
end
