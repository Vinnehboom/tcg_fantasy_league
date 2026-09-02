# The extra player_seasons join level (C-25) pushed this over Metrics/ClassLength
# by a handful of lines; the actions and private helpers are otherwise unchanged.
class RostersController < ScopedGameController # rubocop:disable Metrics/ClassLength

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
    saved = @roster.update(roster_params)
    set_page_variables
    if saved
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
    max_score = @roster.reload.draft.score_for(cost: @roster.remaining_cost)
    @players = Player
               .left_joins(:external_scores)
               .joins("LEFT JOIN (#{latest_scores_by_player.to_sql}) latest_scores ON latest_scores.player_id = players.id") # rubocop:disable Layout/LineLength
               .where.not(id: @roster.player_ids)
    unless @roster.remaining_cost == @roster.draft.price_cap
      @players = @players.where(latest_scores: { score: ...max_score.round })
    end

    @players = group_players_by_region(players: @players)
    @players = apply_filters(players: @players)
    @players = @players.page(params[:page]).per(25)
    @players.each { |player| player.cost = @roster.draft.cost_for(player:) }
  end

  # external_scores has no player_id column, so the "latest row per player" join
  # brings player_seasons into both the outer select and the ranking subquery.
  def latest_scores_by_player
    ExternalScore
      .select('player_seasons.player_id, external_scores.score, external_scores.created_at')
      .from(<<~SQL.squish)
        external_scores
        JOIN player_seasons ON player_seasons.id = external_scores.player_season_id,
        (
          SELECT player_seasons.player_id,
                 ROW_NUMBER() OVER (PARTITION BY player_seasons.player_id ORDER BY external_scores.created_at DESC) AS rn
          FROM external_scores
          JOIN player_seasons ON player_seasons.id = external_scores.player_season_id
        ) ranked_scores
      SQL
      .where('player_seasons.player_id = ranked_scores.player_id AND ranked_scores.rn = 1')
  end

  def group_players_by_region(players:)
    tournament_region = Country[@roster.tournament.country].region
    region_countries = Country.collect_countries_with(tournament_region, :region).map(&:alpha2).reject { |c| c == 'IS' }
    players.order(Arel.sql("players.country = ANY(ARRAY['#{region_countries.join("', '")}']::text[]) DESC"))
           .order('latest_scores.created_at ASC')
  end

end
