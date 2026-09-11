require 'rails_helper'
require 'yaml'

RSpec.describe 'render.yaml' do
  subject(:cron_service) { services_of_type('cron').sole }

  def blueprint
    YAML.safe_load_file(Rails.root.join('render.yaml'))
  end

  def services_of_type(type)
    blueprint.fetch('services').select { |service| service['type'] == type }
  end

  describe 'the retention cron service' do
    it 'runs at the top of every hour' do
      expect(cron_service['schedule']).to eq('0 * * * *')
    end

    it 'runs the retention job' do
      expect(cron_service['startCommand']).to include(ExternalData::RetentionJob.name)
    end

    it 'runs the job inside the cron process, where a raised error fails the run' do
      expect(cron_service['startCommand']).to include('perform_now')
    end

    it 'never hands the job to the queue, which would drop it when the process exits' do
      expect(cron_service['startCommand']).not_to include('perform_later')
    end

    it 'reads the database the web service uses' do
      database_var = cron_service.fetch('envVars').find { |var| var['key'] == 'DATABASE_URL' }

      expect(database_var.dig('fromDatabase', 'name')).to eq('tcg-fantasy-league-production')
    end
  end
end
