module Demo

  # The demo's game list (H-9, Decisions D3): one GameEntry per game, with
  # every per-game value it needs — score band and shape, history curve,
  # counts. Data, not classes: nothing here is a Game subclass, and nothing
  # in Demo::Seeder, Demo::History or Demo::DraftSeeder looks an entry up by
  # id — they iterate Games::ALL instead. Onboarding a new game to the demo
  # means adding a row here, not a branch anywhere else.
  module Games

    ALL = [
      GameEntry.new(
        id: 'PTCG',
        name: 'Pokémon TCG',
        base_uri: 'https://limitlesstcg.com',
        season_label: '2026',
        shape: ExternalData::Synthetic::Shape.new(
          score_range: (200..1600), score_curve: ExternalData::Synthetic::ScoreCurves::LADDER,
          player_count: 64, tournament_count: 3
        ),
        history_curve: Demo::HistoryCurves::ACCUMULATING,
        past_tournament_count: 3
      ),
      GameEntry.new(
        id: 'RIFT',
        name: 'Riftbound',
        base_uri: 'https://example.com/riftbound', # D-1 corrects this once Riftbound has a real source.
        season_label: '2026',
        shape: ExternalData::Synthetic::Shape.new(
          score_range: (1000..1600), score_curve: ExternalData::Synthetic::ScoreCurves::ELO_BAND,
          player_count: 64, tournament_count: 3
        ),
        history_curve: Demo::HistoryCurves::WANDERING,
        past_tournament_count: 3
      )
    ].freeze

  end

end
