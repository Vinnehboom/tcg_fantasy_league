module Admin

  class TournamentsController < ApplicationController

    def index
      @tournaments = Tournament.order(starting_date: :desc).page(params[:page])
    end

  end

end
