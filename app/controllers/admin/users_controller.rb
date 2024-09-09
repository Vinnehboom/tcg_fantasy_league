module Admin

  class UsersController < ApplicationController

    def index
      @users = User.all.page(params[:page])
    end

    def show
      @user = User.find(params[:id])
      @participations = @user.participations
    end

  end

end
