module ExternalData

  class ImportTournamentsJob < ExternalData::ImportJob

    private

    def kind
      :tournaments
    end

    def fetch(interface)
      interface.update_upcoming_tournaments
    end

  end

end
