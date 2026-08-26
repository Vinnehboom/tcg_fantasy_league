module Admin

  module Api

    module Tournaments

      class ResultsController < Admin::ApplicationController

        def update
          tournament = Tournament.find(params[:tournament_id])
          authorize tournament, :update_results?

          job_class = tournament.game.results_import_job
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

end
