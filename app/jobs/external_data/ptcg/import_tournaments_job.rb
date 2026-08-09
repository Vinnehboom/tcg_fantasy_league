module ExternalData

  module Ptcg

    class ImportTournamentsJob < ExternalData::ImportJob

      private

      def game
        Game.find('PTCG')
      rescue ActiveRecord::RecordNotFound
        raise "#{self.class.name}: no Game row with id 'PTCG' — seed it before running this job."
      end

      def adapter
        ExternalData::Pokemon::Tcg::Adapter.new
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
