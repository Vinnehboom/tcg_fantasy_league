module ExternalData

  module Synthetic

    # The real collaborator config/environments/development.rb points
    # adapter_builder at (H-9 review round 1, B3): plain and directly
    # testable, instead of a lambda literal a spec could only ever
    # duplicate. Ignores the live-adapter block entirely, so the real
    # Pokemon adapter is never constructed here.
    class AdapterBuilder

      def call(game:, &_live_adapter)
        Adapter.new(game:)
      end

    end

  end

end
