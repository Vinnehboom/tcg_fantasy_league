class RostersController < ScopedGameController

  before_action :authenticate_user!

  def show
    @roster = Roster.find(params[:id])
  end

  def edit
    @roster = Roster.find(params[:id])
    authorize @roster
    @players = @game.players.page(params[:page]).per(25)
  end

  def create
    @roster = Roster.new(roster_params)
    authorize @roster
    if @roster.save
      redirect_to [@game, @roster], notice: t('.success')
    else
      flash[:error] = t('.failed')
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @roster = Roster.find(params[:id])
    authorize @roster
    @players = @game.players.page(params[:page]).per(25)
    if @roster.update(roster_params)
      respond_to do |format|
        format.html { redirect_to [@game, @roster], notice: t('.success') }
        format.turbo_stream
      end
    else
      flash[:error] = t('.failed')
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream
      end
    end
  end

  def destroy
    @roster = Roster.find(params[:id])
    authorize @roster
    if @roster.destroy
      redirect_to game_rosters_path, notice: t('.success')
    else
      redirect_to [@game, @roster], error: t('.failed')
    end
  end

  private

  def roster_params
    params.require(:roster).permit(:participation_id, roster_players_attributes: %i[id player_id _destroy])
  end

end
