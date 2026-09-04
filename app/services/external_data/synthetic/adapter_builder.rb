module ExternalData

  module Synthetic

    class AdapterBuilder

      def call(game:, &_registered_adapter)
        Adapter.new(game:)
      end

    end

  end

end
