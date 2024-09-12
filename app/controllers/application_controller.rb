class ApplicationController < ActionController::Base

  include Pundit::Authorization
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :unauthorized

  layout :layout_by_resource

  private

  def layout_by_resource
    if devise_controller?
      'no_header'
    else
      'application'
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
  end

  def unauthorized
    game = Game.find_by(id: params[:game])
    if game
      redirect_to game_root_path(game: params[:game]), alert: t('application.unauthorized')
    else
      redirect_to root_path, alert: t('application.unauthorized')
    end
  end

end
