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

      return render_error(:blank) if results_source_id.blank?

      case verify(results_source_id)
      when :verified then update_results_source_id(results_source_id)
      when :not_found then render_error(:not_found)
      when :unavailable then render_error(:verification_unavailable)
      end
    end

    private

    # Confirms the id is real by asking the game's own results source for the
    # tournament's player count, instead of guessing from the string's shape.
    # A positive count means the id resolves to a real tournament (:verified).
    # A game with no registered verifier, or a failed request, means we
    # cannot vouch for the id either way (:unavailable) — distinct from the
    # source actively telling us the id does not exist (:not_found).
    def verify(results_source_id)
      verifier = @tournament.game&.results_verifier
      return :unavailable if verifier.nil?

      verifier.call(results_source_id).present? ? :verified : :not_found
    rescue ExternalData::Exception
      :unavailable
    end

    def update_results_source_id(results_source_id)
      if @tournament.update(results_source_id:)
        redirect_to admin_tournament_path(@tournament), notice: t('.success')
      else
        render_error(:failed)
      end
    end

    def render_error(key)
      flash.now[:alert] = t(".#{key}")
      render :show, status: :unprocessable_entity
    end

  end

end
