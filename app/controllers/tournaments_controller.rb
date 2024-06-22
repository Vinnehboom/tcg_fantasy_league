class TournamentsController < ScopedGameController

  def index
    @tournaments = @game.tournaments.where('starting_date > ?',
                                           DateTime.current).order('starting_date').page(params[:page])
  end

end
