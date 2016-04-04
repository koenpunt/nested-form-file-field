class CreateRestaurants < ActiveRecord::Migration[5.0]
  def change
    create_table :restaurants do |t|
      t.string :name
      t.string :logo
      t.belongs_to :user, foreign_key: true

      t.timestamps
    end
  end
end
