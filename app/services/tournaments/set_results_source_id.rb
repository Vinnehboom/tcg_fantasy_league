module Tournaments

  class SetResultsSourceId < ApplicationService

    def initialize(tournament:, results_source_id:)
      super()
      @tournament = tournament
      @results_source_id = results_source_id
    end

    def call
      return false if results_source_id.blank?

      tournament.update(results_source_id:)
    end

    private

    attr_reader :tournament, :results_source_id

  end

end
