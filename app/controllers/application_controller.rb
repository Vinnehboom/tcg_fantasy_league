class ApplicationController < ActionController::Base

  include Pundit::Authorization
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :unauthorized

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
  end

  def unauthorized
    redirect_to root_path, alert: t('application.unauthorized')
  end

end
