namespace :demo do
  desc 'Seed the demo dataset: synthetic players, tournaments, drafts and history. Additive and idempotent.'
  task seed: :environment do
    Demo::Seeder.call
    Demo::History.call
    Demo::DraftSeeder.call
  end

  desc 'Reset (erase every table) then reseed the demo dataset. Requires CONFIRM=yes.'
  task reseed: :environment do
    if ENV['CONFIRM'] == 'yes'
      Demo::Reset.call(confirm: true)
      Rake::Task['demo:seed'].invoke
    else
      connection = ActiveRecord::Base.connection
      puts "Refusing: this would truncate #{connection.tables.length} tables in database " \
           "'#{connection.pool.db_config.database}', including users."
      puts 'Re-run with CONFIRM=yes to proceed: rake demo:reseed CONFIRM=yes'
    end
  end
end
