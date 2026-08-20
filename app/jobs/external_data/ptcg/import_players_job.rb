module ExternalData

  module Ptcg

    class ImportPlayersJob < ExternalData::ImportJob

      private

      def game
        Game.find('PTCG')
      rescue ActiveRecord::RecordNotFound
        raise "#{self.class.name}: no Game row with id 'PTCG' — seed it before running this job."
      end

      def adapter
        ExternalData::Pokemon::Tcg::Adapter.new(game:)
      end

      def kind
        :players
      end

      def fetch(interface)
        interface.update_players
      end

    end

  end

end
