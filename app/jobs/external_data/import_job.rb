module ExternalData

  class ImportJob < ApplicationJob

    queue_as :imports

    # A job-level backstop on top of JsonApiClient's own per-request
    # RetryPolicy, scoped to the same retryable errors so the two don't
    # contradict.
    retry_on ExternalData::JsonApiClient::TimeoutError,
             ExternalData::JsonApiClient::RateLimitError,
             wait: :polynomially_longer, attempts: ExternalData::RetryPolicy.new.max_attempts

    # An injected adapter cannot survive ActiveJob serialization, so this
    # only works with #perform_now; #perform_later must pass game_id: only.
    def perform(game_id:, adapter: nil)
      @game_id = game_id
      @injected_adapter = adapter
      run_import
    end

    def retry_job(**options)
      return super unless @injected_adapter

      raise options.fetch(:error)
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
      @adapter ||= @injected_adapter || game.adapter
    end

    def kind
      raise '#kind not implemented'
    end

    def fetch(*)
      raise '#fetch not implemented'
    end

  end

end
