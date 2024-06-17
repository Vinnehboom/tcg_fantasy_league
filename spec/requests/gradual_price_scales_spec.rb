require 'rails_helper'

RSpec.describe 'GradualPriceScales' do
  let(:user) { create(:user) }
  let(:gradual_scaling_price) { create(:gradual_scaling_price) }

  before do
    sign_in(user)
  end

  describe '#new' do
    it 'shows the pricing rule form' do
      get new_gradual_scaling_price_gradual_price_scale_path(gradual_scaling_price)
      expect(response).to render_template('gradual_price_scales/new')
    end
  end

  describe '#create' do
    describe 'when the information is valid' do
      let(:params) do
        {
          gradual_price_scale: {
            point_coefficient: 5.0,
            minimum_price: 0.0,
            maximum_price: 10.0
          }
        }
      end

      it 'adds the scale' do
        expect do
          post gradual_scaling_price_gradual_price_scales_path(gradual_scaling_price),
               params:
        end.to change(GradualPriceScale, :count).by(1)
      end

      it 'shows the related pricing rule' do
        post(gradual_scaling_price_gradual_price_scales_path(gradual_scaling_price), params:)
        expect(response).to redirect_to(gradual_scaling_price)
      end
    end

    describe 'when the information is invalid' do
      let(:params) do
        {
          gradual_price_scale: {
            point_coefficient: 5.0,
            minimum_price: 0.0
          }
        }
      end

      it 'does not add the price scale' do
        expect do
          post gradual_scaling_price_gradual_price_scales_path(gradual_scaling_price),
               params:
        end.not_to change(GradualPriceScale, :count)
      end

      it 'shows the form' do
        post(gradual_scaling_price_gradual_price_scales_path(gradual_scaling_price), params:)
        expect(response).to render_template('gradual_price_scales/new')
      end
    end
  end

  describe '#edit' do
    let(:gradual_price_scale) { create(:gradual_price_scale, gradual_scaling_price:) }

    it 'shows the pricing rule form' do
      get edit_gradual_scaling_price_gradual_price_scale_path(gradual_scaling_price, gradual_price_scale)
      expect(response).to render_template('gradual_price_scales/edit')
    end
  end

  describe '#update' do
    let(:gradual_price_scale) { create(:gradual_price_scale, gradual_scaling_price:, point_coefficient: 5.0) }

    describe 'when the information is valid' do
      let(:params) do
        {
          gradual_price_scale: {
            point_coefficient: 8.0,
            minimum_price: 0.0,
            maximum_price: 10.0
          }
        }
      end

      it 'updates the scale information' do
        put(gradual_scaling_price_gradual_price_scale_path(gradual_scaling_price, gradual_price_scale), params:)
        expect(gradual_price_scale.reload.point_coefficient).to eq(8.0)
      end

      it 'shows the related pricing rule' do
        put(gradual_scaling_price_gradual_price_scale_path(gradual_scaling_price, gradual_price_scale), params:)
        expect(response).to redirect_to(gradual_scaling_price)
      end
    end

    describe 'when the information is invalid' do
      let(:params) do
        {
          gradual_price_scale: {
            point_coefficient: 'test',
            minimum_price: nil
          }
        }
      end

      it 'does not update the price scale' do
        put(gradual_scaling_price_gradual_price_scale_path(gradual_scaling_price, gradual_price_scale), params:)
        expect(gradual_price_scale.reload.point_coefficient).not_to eq('test')
      end

      it 'shows the form' do
        put(gradual_scaling_price_gradual_price_scale_path(gradual_scaling_price, gradual_price_scale), params:)
        expect(response).to render_template('gradual_price_scales/edit')
      end
    end
  end

  describe '#destroy' do
    let!(:gradual_price_scale) { create(:gradual_price_scale, gradual_scaling_price:) }

    it 'removes the price scale' do
      expect do
        delete gradual_scaling_price_gradual_price_scale_path(gradual_scaling_price,
                                                              gradual_price_scale)
      end.to change(GradualPriceScale, :count).by(-1)
    end
  end
end
