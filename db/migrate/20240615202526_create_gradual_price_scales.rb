class CreateGradualPriceScales < ActiveRecord::Migration[7.1]
  def change
    create_table :gradual_price_scales do |t|
      t.references :gradual_scaling_price, null: false, foreign_key: {to_table: :pricing_rules}
      t.decimal :point_coefficient
      t.decimal :minimum_price
      t.decimal :maximum_price

      t.timestamps
    end
  end
end
