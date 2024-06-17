class PricingRulesController < ApplicationController

  before_action :authenticate_user!

  def index
    @pricing_rules = PricingRule.all.page(params[:page])
  end

  def new
    @pricing_rule = PricingRule.new
    @pricing_rule_types = PricingRule.subclasses.map(&:to_s)
    Rails.logger.debug @pricing_rule_types
  end

  def create
    @pricing_rule = PricingRule.new(pricing_rule_params)
    if @pricing_rule.save
      redirect_to @pricing_rule, notice: t('.success')
    else
      flash[:alert] = t('.error')
      render :new
    end
  end

  private

  def pricing_rule_params
    params.require(:pricing_rule).permit(:type, :name)
  end

end
