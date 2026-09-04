module ExternalData

  class ImportPlayersJob < ExternalData::ImportJob

    private

    def kind
      :players
    end

    def fetch(interface)
      interface.update_players
    end

  end

end
