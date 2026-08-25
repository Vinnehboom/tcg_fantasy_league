module Admin

  module Api

    class TournamentsController < Admin::ApplicationController

      def results_source_id
        tournament = Tournament.find(params[:id])
        authorize tournament, :set_results_source_id?

        if Tournaments::SetResultsSourceId.call(tournament:, results_source_id: params[:results_source_id])
          head :ok
        else
          head :unprocessable_entity
        end
      end

    end

  end

end
