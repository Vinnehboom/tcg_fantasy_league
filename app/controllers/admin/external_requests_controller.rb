module Admin

  class ExternalRequestsController < ApplicationController

    ERROR_PREVIEW_LENGTH = 50

    helper_method :error_preview_length

    def index
      @games = Game.order(:name).to_a
      @game = @games.find { |game| game.id == params[:game] } || @games.first
      @external_requests = requests_for(@game).page(params[:page])
    end

    def show
      @external_request = ExternalRequest.find(params[:id])
    end

    private

    def error_preview_length
      ERROR_PREVIEW_LENGTH
    end

    def requests_for(game)
      return ExternalRequest.none unless game

      game.external_requests.kept.order(started_at: :desc)
    end

  end

end
