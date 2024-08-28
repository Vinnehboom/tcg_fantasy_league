class TournamentsController < ApplicationController

  def index
    @tournaments = Tournament.where('starting_date > ?', DateTime.current).order('starting_date').page(params[:page])
  end

end
