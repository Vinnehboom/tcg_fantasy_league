module Demo

  # One game's demo data (H-9, Decisions D3): its identity, its season label,
  # the Shape its synthetic adapter should use, the history curve Demo::History
  # backdates with, and how many past tournaments to seed for it. Held in a
  # plain list (see Demo::Games) — never looked up by id.
  GameEntry = Struct.new(:id, :name, :base_uri, :season_label, :shape, :history_curve, :past_tournament_count,
                         keyword_init: true)

end
