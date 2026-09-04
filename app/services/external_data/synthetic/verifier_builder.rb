module ExternalData

  module Synthetic

    # Swaps in the synthetic verifier only for a game that actually has one
    # registered, so an unregistered game stays unavailable rather than
    # getting a stub for a verifier that was never promised.
    class VerifierBuilder

      def call(**, &registered_verifier)
        return if registered_verifier.call.nil?

        ResultsVerifier.new
      end

    end

  end

end
