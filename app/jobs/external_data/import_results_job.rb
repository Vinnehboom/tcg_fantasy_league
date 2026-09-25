module ExternalData

  class ImportResultsJob < ExternalData::ImportJob

    def perform(tournament_id:, adapter: nil)
      @tournament_id = tournament_id
      @injected_adapter = adapter
      run_import
    end

    private

    def game
      tournament.game
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
