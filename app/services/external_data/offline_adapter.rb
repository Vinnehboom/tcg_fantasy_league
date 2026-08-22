module ExternalData

  class OfflineAdapter

    def players
      raise ExternalData::Exception.new('Offline method called',
                                        'the #players method was called on an invalid adapter')
    end

    def upcoming_tournaments
      raise ExternalData::Exception.new('Offline method called',
                                        'the #upcoming_tournaments method was called on an invalid adapter')
    end

    def results(**)
      raise ExternalData::Exception.new('Offline method called',
                                        'the #results method was called on an invalid adapter')
    end

  end

end
