module ExternalData

  module Synthetic

    # Everything ExternalData::Synthetic::Adapter needs to know about one
    # game's demo data besides its seed: the score band and curve, and how
    # many players and tournaments to invent. Bundled into one value so the
    # adapter (and Demo::Games, and the demo composition roots that inject
    # the adapter into the generic import jobs) pass it around as a single
    # collaborator instead of four separate parameters.
    Shape = Struct.new(:score_range, :score_curve, :player_count, :tournament_count, keyword_init: true)

  end

end
