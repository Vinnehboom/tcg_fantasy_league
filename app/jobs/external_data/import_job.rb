module ExternalData

  class ImportJob < ApplicationJob

    queue_as :imports

    # Job-level backstop, layered on top of (not replacing) JsonApiClient's own per-request
    # RetryPolicy: a request-level retry smooths a brief blip within one fetch, this re-enqueues
    # the whole job once that budget is exhausted, covering a sustained outage or rate-limit
    # window longer than one request's own retries can absorb. Scoped to the same retryable set
    # RetryPolicy already uses (timeouts + 429, not 5xx) so the two layers don't contradict.
    retry_on ExternalData::JsonApiClient::TimeoutError,
             ExternalData::JsonApiClient::RateLimitError,
             wait: :polynomially_longer, attempts: ExternalData::RetryPolicy.new.max_attempts

    # An injected +adapter+ is a plain object, not an ActiveRecord-backed
    # GlobalID, so it cannot survive ActiveJob's argument serialization —
    # this form only works with #perform_now. Demo::Seeder and Demo::History
    # call it that way, injecting a synthetic adapter directly. Anything
    # queued with #perform_later (the admin-triggered imports, the cron
    # schedule) must pass game_id: only and let #adapter resolve the game's
    # own registered adapter.
    def perform(game_id:, adapter: nil)
      @game_id = game_id
      @adapter = adapter
      run_import
    end

    private

    def run_import
      current_game = game
      current_adapter = adapter

      ExternalData::RequestRecorder.call(game: current_game, kind:, source_url: current_game.base_uri) do |_request|
        interface = ExternalData::Interface.new(game: current_game, adapter: current_adapter)
        build_result(records_processed: fetch(interface))
      end
    end

    def build_result(records_processed:)
      Struct.new(:records_processed, :requestable, keyword_init: true).new(records_processed:, requestable:)
    end

    def requestable
      nil
    end

    def game
      @game ||= ::Game.find(@game_id)
    rescue ActiveRecord::RecordNotFound
      raise "#{self.class.name}: no Game row with id '#{@game_id}' — seed it before running this job."
    end

    def adapter
      @adapter ||= game.adapter
    end

    def kind
      raise '#kind not implemented'
    end

    def fetch(*)
      raise '#fetch not implemented'
    end

  end

end
