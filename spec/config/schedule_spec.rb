require 'rails_helper'
require 'whenever'

RSpec.describe 'config/schedule.rb' do
  subject(:job_list) { Whenever::JobList.new(file: Rails.root.join('config/schedule.rb').to_s) }

  it 'resolves every job class it references' do
    expect { job_list }.not_to raise_error
  end

  it 'does not enqueue the daily PTCG import jobs while paused' do
    expect(job_list.generate_cron_output)
      .not_to include('ExternalData::Ptcg::ImportPlayersJob.perform_later')
    expect(job_list.generate_cron_output)
      .not_to include('ExternalData::Ptcg::ImportTournamentsJob.perform_later')
  end
end
