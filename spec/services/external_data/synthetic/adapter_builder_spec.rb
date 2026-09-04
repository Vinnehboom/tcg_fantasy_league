require 'rails_helper'

RSpec.describe ExternalData::Synthetic::AdapterBuilder do
  subject(:builder) { described_class.new }

  let(:game) { create(:game) }

  it 'returns a synthetic adapter for the given game' do
    expect(builder.call(game:)).to be_a(ExternalData::Synthetic::Adapter)
  end

  it 'never invokes the live-adapter block, so the real adapter is not constructed' do
    expect { builder.call(game:) { raise 'the real adapter must not be constructed' } }.not_to raise_error
  end
end
