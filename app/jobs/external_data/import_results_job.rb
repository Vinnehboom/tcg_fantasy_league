module ExternalData

  # Results are scoped to one tournament rather than one game, so this job
  # takes tournament_id: instead of game_id: and derives its game from the
  # tournament — the same adapter-injection contract as the base class
  # still applies (see ImportJob#perform).
  class ImportResultsJob < ExternalData::ImportJob

    def perform(tournament_id:, adapter: nil)
      @tournament_id = tournament_id
      @adapter = adapter
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
