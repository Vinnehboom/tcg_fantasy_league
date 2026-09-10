require 'rails_helper'
require 'whenever'

RSpec.describe 'config/schedule.rb' do
  subject(:job_list) { Whenever::JobList.new(file: Rails.root.join('config/schedule.rb').to_s) }

  it 'resolves every job class it references' do
    expect { job_list }.not_to raise_error
  end

  it 'does not enqueue the daily PTCG import jobs while paused' do
    expect(job_list.generate_cron_output)
      .not_to include('ExternalData::ImportPlayersJob.perform_later')
    expect(job_list.generate_cron_output)
      .not_to include('ExternalData::ImportTournamentsJob.perform_later')
  end

  it 'enqueues the external request retention job' do
    expect(job_list.generate_cron_output).to include("#{ExternalData::RetentionJob.name}.perform_later")
  end

  it 'runs the retention job at the top of every hour' do
    retention_line = job_list.generate_cron_output.lines.grep(/#{ExternalData::RetentionJob.name}/).sole

    expect(retention_line).to start_with('0 * * * *')
  end
end
