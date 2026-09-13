class PlayersController < ScopedGameController

  def index
    @players = @game.players.not_suppressed.joins(:external_scores)
    @countries = @players.where.not(country: [nil, '']).distinct.pluck(:country).sort
    @players = apply_filters(players: @players)
               .group('players.id')
               .order('max(external_scores.score) desc')
    @players = @players.page(params[:page]).per(25)
    @filters = filter_params
  end

  private

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

end
