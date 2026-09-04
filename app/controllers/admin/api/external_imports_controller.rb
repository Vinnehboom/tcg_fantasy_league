module Admin

  module Api

    class ExternalImportsController < Admin::ApplicationController

      IMPORT_JOBS = {
        %w[PTCG players] => ExternalData::ImportPlayersJob,
        %w[PTCG tournaments] => ExternalData::ImportTournamentsJob
      }.freeze

      def create
        game = Game.find(params[:game_id])
        authorize game, :trigger_import?

        job_class = IMPORT_JOBS[[params[:game_id], params[:kind]]]
        if job_class
          job_class.perform_later(game_id: params[:game_id])
          head :ok
        else
          head :unprocessable_entity
        end
      end

    end

  end

end
