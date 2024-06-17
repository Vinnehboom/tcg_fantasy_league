class GradualPriceScalesController < ApplicationController

  before_action :authenticate_user!
  before_action :set_gradual_scaling_price

  def new
    @gradual_price_scale = @gradual_scaling_price.gradual_price_scales.new
  end

  def edit
    @gradual_price_scale = GradualPriceScale.find(params[:id])
  end

  def create
    @gradual_price_scale = @gradual_scaling_price.gradual_price_scales.new(gradual_price_scale_params)
    if @gradual_price_scale.save
      redirect_to @gradual_scaling_price, notice: t('.success')
    else
      flash[:error] = t('.error')
      render :new
    end
  end

  def update
    @gradual_price_scale = GradualPriceScale.find(params[:id])
    if @gradual_price_scale.update(gradual_price_scale_params)
      redirect_to @gradual_scaling_price, notice: t('.success')
    else
      flash[:error] = t('.error')
      render :edit
    end
  end

  def destroy
    @gradual_price_scale = GradualPriceScale.find(params[:id])
    @gradual_price_scale.destroy!
    redirect_to @gradual_scaling_price, notice: t('.success')
  end

  private

  def set_gradual_scaling_price
    @gradual_scaling_price = GradualScalingPrice.find(params[:gradual_scaling_price_id])
  end

  def gradual_price_scale_params
    params.require(:gradual_price_scale).permit(:minimum_price, :maximum_price, :point_coefficient)
  end

end
