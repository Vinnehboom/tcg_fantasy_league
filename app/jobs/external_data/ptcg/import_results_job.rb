module ExternalData

  module Ptcg

    class ImportResultsJob < ExternalData::ImportJob

      def perform(tournament_id:)
        @tournament_id = tournament_id
        run_import
      end

      private

      def game
        Game.ptcg || raise("#{self.class.name}: no Game row with id 'PTCG' — seed it before running this job.")
      end

      def adapter
        @adapter ||= ExternalData::Pokemon::Tcg::Adapter.new(game:)
      end

      def kind
        :results
      end

      def fetch(interface)
        interface.update_results(tournament:, field_size: adapter.field_size(tournament:))
      end

      def requestable
        tournament
      end

      def tournament
        @tournament ||= ::Tournament.find(@tournament_id)
      end

    end

  end

end
