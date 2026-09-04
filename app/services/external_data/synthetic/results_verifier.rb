module ExternalData

  module Synthetic

    # Stands in for a game's real results_verifier lambda (H-9), so that
    # confirming a results_source_id in local development makes no live HTTP
    # call either — not just the imports. Game-agnostic and deterministic:
    # the same results_source_id always answers with the same count, derived
    # from a Zlib.crc32 digest of the id, never String#hash (randomized per
    # process).
    class ResultsVerifier

      def initialize
        raise_outside_the_sandbox!
      end

      def call(results_source_id)
        return if results_source_id.blank?

        (Zlib.crc32(results_source_id) % 5_000) + 1
      end

      private

      def raise_outside_the_sandbox!
        return unless Rails.env.production?

        raise ExternalData::Exception.new(
          'Synthetic verifier invalid in production',
          "#{self.class.name} must never run against the production database"
        )
      end

    end

  end

end
