module Admin

  class ParticipationsController < ApplicationController

    def index
      @participations = Participation.all.page(params[:page])
    end

    def show
      @participation = Participation.find(params[:id])
      @rosters = @participation.rosters
    end

  end

end
