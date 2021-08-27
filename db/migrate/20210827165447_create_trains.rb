class CreateTrains < ActiveRecord::Migration[6.1]
  def change
    create_table :trains do |t|

      t.timestamps
    end
  end
end
