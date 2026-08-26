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

      results_source_id = params[:results_source_id].to_s.strip

      if results_source_id.blank?
        flash.now[:alert] = t('.blank')
        render :show, status: :unprocessable_entity
      elsif !verified_results_source_id?(results_source_id)
        flash.now[:alert] = t('.not_found')
        render :show, status: :unprocessable_entity
      elsif @tournament.update(results_source_id:)
        redirect_to admin_tournament_path(@tournament), notice: t('.success')
      else
        flash.now[:alert] = t('.failed')
        render :show, status: :unprocessable_entity
      end
    end

    private

    # Confirms the id is real by asking the source itself for the tournament's
    # player count, instead of guessing from the string's shape. A positive
    # count means the id resolves to a real tournament; a nil result or a
    # failed request both mean we cannot vouch for the id, so we reject it.
    def verified_results_source_id?(results_source_id)
      ExternalData::Pokemon::Tcg::LabsTournament.call(tournament_id: results_source_id).present?
    rescue ExternalData::Exception
      false
    end

  end

end
