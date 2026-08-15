module Admin

  class ExternalImportsController < ApplicationController

    IMPORT_JOBS = {
      %w[PTCG players] => ExternalData::Ptcg::ImportPlayersJob,
      %w[PTCG tournaments] => ExternalData::Ptcg::ImportTournamentsJob
    }.freeze

    def index
      @game = Game.find_by(id: 'PTCG')
    end

    def create
      game = Game.find(params[:game_id])
      authorize game, :trigger_import?

      job_class = IMPORT_JOBS[[params[:game_id], params[:kind]]]
      if job_class
        job_class.perform_later
        head :ok
      else
        head :unprocessable_entity
      end
    end

  end

end
