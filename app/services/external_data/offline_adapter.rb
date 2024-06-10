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

    def self.update_players
      raise CustomException.new('Offline method called', self.class.name,
                                'the #update_players method was called on an invalid adapter')
    end

  end

end
