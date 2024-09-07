class ParticipationsController < ScopedGameController

  before_action :authenticate_user!

  def index
    @participations = current_user.participations.includes(draft: :tournament)
                                  .where('tournament.game': @game)
                                  .page(params[:page])
  end

  def show
    @participation = Participation.find(params[:id])
    @rosters = @participation.rosters
    authorize @participation
  end

  def create
    @participation = Participation.new(participation_params)
    authorize @participation
    if @participation.save
      redirect_to [@game, @participation], notice: t('.success')
    else
      flash[:error] = t('.failed')
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @participation = Participation.includes(rosters: :roster_players).find(params[:id])
    authorize @participation

    if @participation.update(update_params)
      redirect_to [@game, @participation], notice: t('.success')
    else
      redirect_to [@game, @participation], alert: t('.failed')
    end
  end

  def destroy
    @participation = Participation.find(params[:id])
    authorize @participation
    if @participation.destroy
      redirect_to game_participations_path(game: @game), notice: t('.success')
    else
      flash[:error] = t('.failed')
      redirect_to [@game, @participation]
    end
  end

  private

  def participation_params
    params.require(:participation).permit(:draft_id, :user_id)
  end

  def update_params
    params.require(:participation).permit(:status)
  end

end
