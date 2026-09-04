module ExternalData

  module Synthetic

    # A demo composition root: unlike the base ImportJob#adapter, this never
    # reads the configured adapter_builder, so it always uses the synthetic
    # adapter with the shape Demo::History gives it — in every environment,
    # development included (see H-9, Decisions D13). Callers must pass the
    # same seed and shape given to ImportPlayersJob for this game, or the
    # player pools diverge and ExternalData::Result#resolved_player silently
    # creates scoreless players.
    class ImportResultsJob < ExternalData::ImportJob

      def perform(tournament_id:, seed: ExternalData::Synthetic::Adapter::DEFAULT_SEED,
                  shape: ExternalData::Synthetic::Adapter::DEFAULT_SHAPE)
        @tournament_id = tournament_id
        @seed = seed
        @shape = shape
        run_import
      end

      private

      attr_reader :tournament_id, :seed, :shape

      def game
        tournament.game
      end

      def adapter
        @adapter ||= ExternalData::Synthetic::Adapter.new(game:, seed:, shape:)
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
        @tournament ||= ::Tournament.find(tournament_id)
      end

    end

  end

end
