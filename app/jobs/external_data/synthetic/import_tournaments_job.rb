module ExternalData

  module Synthetic

    # A demo composition root: unlike the base ImportJob#adapter, this never
    # reads the configured adapter_builder, so it always uses the synthetic
    # adapter with the shape Demo::Seeder gives it — in every environment,
    # development included (see H-9, Decisions D13).
    class ImportTournamentsJob < ExternalData::ImportJob

      def perform(game_id:, seed: ExternalData::Synthetic::Adapter::DEFAULT_SEED,
                  shape: ExternalData::Synthetic::Adapter::DEFAULT_SHAPE)
        @game_id = game_id
        @seed = seed
        @shape = shape
        run_import
      end

      private

      attr_reader :game_id, :seed, :shape

      def game
        @game ||= ::Game.find(game_id)
      end

      def adapter
        @adapter ||= ExternalData::Synthetic::Adapter.new(game:, seed:, shape:)
      end

      def kind
        :tournaments
      end

      def fetch(interface)
        interface.update_upcoming_tournaments
      end

    end

  end

end
