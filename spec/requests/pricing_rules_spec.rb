require 'rails_helper'

RSpec.describe 'PricingRules' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe '#index' do
    it 'shows all pricing rules' do
      get pricing_rules_path
      expect(response).to render_template('pricing_rules/index')
    end
  end

  describe '#new' do
    it 'shows the pricing rule form' do
      get new_pricing_rule_path
      expect(response).to render_template('pricing_rules/new')
    end
  end

  describe '#create' do
    describe 'when the information is valid' do
      let(:params) do
        {
          pricing_rule: {
            type: PricingRule.subclasses.sample.to_s,
            name: 'test'
          }
        }
      end

      it 'adds the pricing rule' do
        expect { post pricing_rules_path, params: }.to change(PricingRule, :count).by(1)
      end

      it 'shows the pricing rule information' do
        post(pricing_rules_path, params:)
        expect(response).to redirect_to(PricingRule.last)
      end
    end

    describe 'when the information is invalid' do
      let(:params) do
        {
          pricing_rule: {
            type: PricingRule.subclasses.sample.to_s
          }
        }
      end

      it 'does not add the pricing rule' do
        expect { post pricing_rules_path, params: }.not_to change(PricingRule, :count)
      end

      it 'shows the form' do
        post(pricing_rules_path, params:)
        expect(response).to render_template('pricing_rules/new')
      end
    end
  end
end
