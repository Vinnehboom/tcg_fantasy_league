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
    @players = @game.players
    @countries = @players.pluck(:country).uniq.sort
    filter_players
    @filters = filter_params
    @price_rules = Players::ScalingPriceRule.new
  end

  def filter_players
    tournament_region = Country[@roster.tournament.country].region
    region_countries = Country.collect_countries_with(tournament_region, :region).map(&:alpha2).reject { |c| c == 'IS' }
    latest_scores = ExternalScore
                    .select('external_scores.player_id, external_scores.score, external_scores.created_at')
                    .from('external_scores, (SELECT player_id, ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY created_at DESC) AS rn FROM external_scores) ranked_scores') # rubocop:disable Layout/LineLength
                    .where('external_scores.player_id = ranked_scores.player_id AND ranked_scores.rn = 1')

    @players = Player
               .left_joins(:external_scores)
               .joins("LEFT JOIN (#{latest_scores.to_sql}) latest_scores ON latest_scores.player_id = players.id")
               .order(Arel.sql("players.country = ANY(ARRAY['#{region_countries.join("', '")}']::text[]) DESC"))
               .order('latest_scores.created_at ASC')
    @players = apply_filters(players: @players)
    @players = @players.page(params[:page]).per(25)
    @players.each { |player| player.cost = @roster.draft.cost_for(player:) }
  end

end
