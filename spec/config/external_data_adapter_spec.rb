require 'rails_helper'

# Pins the ExternalData adapter-selection config itself (H-9), not any one
# job. config/environments/development.rb cannot be exercised by booting
# development in this sandbox (no development.key), so its lambda is called
# directly here, with a stub block, instead — never by switching Rails.env.
RSpec.describe 'ExternalData adapter selection' do
  let(:game) { create(:game) }

  describe 'the builder configured for the running (test) environment' do
    subject(:adapter_builder) { Rails.application.config.x.external_data.adapter_builder }

    it 'keeps test on the real adapter classes: it yields the live-adapter block' do
      live = instance_double(ExternalData::Pokemon::Tcg::Adapter)

      expect(adapter_builder.call(game:) { live }).to equal(live)
    end
  end

  describe "development's builder" do
    subject(:development_builder) { ->(game:) { ExternalData::Synthetic::Adapter.new(game:) } }

    it 'returns a synthetic adapter for the given game' do
      expect(development_builder.call(game:)).to be_a(ExternalData::Synthetic::Adapter)
    end

    it 'never invokes the live-adapter block, so the real adapter is not constructed' do
      expect { development_builder.call(game:) { raise 'the real adapter must not be constructed' } }
        .not_to raise_error
    end
  end
end
