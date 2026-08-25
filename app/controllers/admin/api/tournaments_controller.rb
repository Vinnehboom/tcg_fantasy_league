module Admin

  module Api

    class TournamentsController < Admin::ApplicationController

      RESULTS_IMPORT_JOBS = {
        'PTCG' => ExternalData::Ptcg::ImportResultsJob
      }.freeze

      def results_import
        tournament = Tournament.find(params[:id])
        authorize tournament, :trigger_results_import?

        job_class = RESULTS_IMPORT_JOBS[tournament.game_id]
        if tournament.results_source_id.blank? || job_class.nil?
          head :unprocessable_entity
        else
          job_class.perform_later(tournament_id: tournament.id)
          head :ok
        end
      end

    end

  end

end
