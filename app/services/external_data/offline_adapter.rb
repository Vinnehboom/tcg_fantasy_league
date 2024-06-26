module ExternalData

  class OfflineAdapter

    def self.players
      raise ExternalData::Exception.new('Offline method called',
                                        'the #players method was called on an invalid adapter')
    end

    def self.update_players
      raise ExternalData::Exception.new('Offline method called',
                                        'the #update_players method was called on an invalid adapter')
    end

    def self.upcoming_tournaments
      raise ExternalData::Exception.new('Offline method called',
                                        'the #upcoming_tournaments method was called on an invalid adapter')
    end

    def self.update_upcoming_tournaments
      raise ExternalData::Exception.new('Offline method called',
                                        'the #update_upcoming_tournaments method was called on an invalid adapter')
    end

  end

end
