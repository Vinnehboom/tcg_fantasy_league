module Admin

  class ApplicationController < ::ApplicationController

    layout 'admin'
    before_action :authenticate_admin!

    private

    def authenticate_admin!
      raise Pundit::NotAuthorizedError unless current_user&.admin?
    end

  end

end
