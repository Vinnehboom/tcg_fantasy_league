class GradualScalingPricesController < ApplicationController

  before_action :authenticate_user!

  def show
    @gradual_scaling_price = GradualScalingPrice.find(params[:id])
  end

end
