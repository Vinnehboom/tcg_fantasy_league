class RostersController < ScopedGameController

  before_action :authenticate_user!

  def show
    @roster = Roster.find(params[:id])
  end

  def edit
    @roster = Roster.find(params[:id])
    authorize @roster
    set_page_variables
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    @roster = Roster.new(roster_params)
    authorize @roster
    if @roster.save
      redirect_to edit_game_roster_path(id: @roster.id, game: @game), notice: t('.success')
    else
      redirect_to [@game, @roster.participation], error: t('.failed')
    end
  end

  def update
    @roster = Roster.find(params[:id])
    authorize @roster
    set_page_variables
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
      redirect_to [@game, @roster.participation], notice: t('.success')
    else
      redirect_to [@game, @roster], error: t('.failed')
    end
  end

  private

  def roster_params
    params.require(:roster).permit(:participation_id, roster_players_attributes: %i[id player_id _destroy])
  end

  def filter_params
    params.permit(:country, :name).compact_blank
  end

  def apply_filters(players:)
    return players if filter_params.blank?

    filter_params.to_h.each do |attribute, value|
      players = players.and(players.contains(attribute, value))
    end

    players
  end

  def set_page_variables
    @players = @game.players.includes(:external_scores)
    @countries = @players.pluck(:country).uniq.sort
    @players = apply_filters(players: @players)
    @players = @players.page(params[:page]).per(25)
    @players.each { |player| player.cost = @roster.draft.cost_for(player:) }
    @filters = filter_params
  end

end
