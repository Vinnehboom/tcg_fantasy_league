# Paused per review feedback on PR #41 — commented out, not removed. Follow-up
# ticket A-10 will track re-enabling this once the current round of Epic A settles.
#
# Referencing job classes as constants (not bare strings) makes whenever's `every` block
# resolve them the moment this file is parsed — by the real `whenever` CLI at deploy time,
# and by spec/config/schedule_spec.rb in CI — so a broken or renamed job class name raises
# immediately instead of silently failing the next time cron fires.
# every 1.day, at: '9:00 am' do
#   runner "#{ExternalData::Ptcg::ImportPlayersJob.name}.perform_later"
#   runner "#{ExternalData::Ptcg::ImportTournamentsJob.name}.perform_later"
# end
