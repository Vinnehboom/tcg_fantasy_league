class UsersController < ScopedGameController

  before_action :authenticate_user!

  def show
    @user = User.find(params[:id])
    @rosters = Roster.where(participation_id: @user.participations.completed.ids).page(params[:page])
  end

end
