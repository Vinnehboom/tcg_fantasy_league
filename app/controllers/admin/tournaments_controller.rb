module Admin

  class TournamentsController < ApplicationController

    def index
      @tournaments = Tournament.order(starting_date: :desc).page(params[:page])
    end

    def show
      @tournament = Tournament.find(params[:id])
    end

    def update
      @tournament = Tournament.find(params[:id])
      authorize @tournament

      results_source_id = extract_results_source_id(params[:results_source_id])

      if results_source_id.present? && @tournament.update(results_source_id:)
        redirect_to admin_tournament_path(@tournament), notice: t('.success')
      else
        flash.now[:alert] = t('.failed')
        render :show, status: :unprocessable_entity
      end
    end

    private

    def extract_results_source_id(value)
      pattern = @tournament.game.results_source_id_url_pattern
      match = pattern&.match(value.to_s)
      match ? match[:results_source_id] : value
    end

  end

end
