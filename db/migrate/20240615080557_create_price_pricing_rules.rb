class CreatePricePricingRules < ActiveRecord::Migration[7.1]
  def change
    create_table :price_pricing_rules do |t|
      t.references :price, null: false, foreign_key: true
      t.references :pricing_rule, null: false, foreign_key: true

      t.timestamps
    end
  end
end
