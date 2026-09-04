module ExternalData

  module Synthetic

    # The real collaborator config/environments/development.rb points
    # verifier_builder at (H-9 review round 1, B3, NB17): plain and directly
    # testable, instead of a lambda literal a spec could only ever
    # duplicate.
    #
    # It swaps in the synthetic verifier only for a game that actually has
    # one registered. A game with none (Riftbound today) stays honestly
    # unavailable, the same as test, staging and production — the point of
    # the stub is no live HTTP call, not a working verifier where one was
    # never promised. Checking the registered verifier's presence is not
    # itself a live call: only calling the verifier it returns would be.
    class VerifierBuilder

      def call(**, &registered_verifier)
        return if registered_verifier.call.nil?

        ResultsVerifier.new
      end

    end

  end

end
