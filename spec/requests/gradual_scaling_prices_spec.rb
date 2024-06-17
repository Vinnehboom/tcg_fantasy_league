require 'rails_helper'

RSpec.describe 'GradualScalingPrices' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe '#show' do
    let(:price_rule) { create(:gradual_scaling_price) }

    it 'shows all information of the gradual scaling price rule' do
      get gradual_scaling_price_path(price_rule)
      expect(response).to render_template('gradual_scaling_prices/show')
    end
  end
end
