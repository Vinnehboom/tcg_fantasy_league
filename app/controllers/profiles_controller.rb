class ProfilesController < ApplicationController

  layout 'no_header'
  before_action :authenticate_user!
  before_action -> { @user = current_user }

  def edit; end

  def update
    if @user.update(profile_params)
      redirect_to root_path, notice: t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:country, :date_of_birth)
  end

end
