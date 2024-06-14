class TournamentsController < ApplicationController

  def index
    @tournaments = Tournament.order('starting_date').page(params[:page])
  end

end
