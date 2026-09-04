require 'rails_helper'

# Pins the ExternalData adapter- and verifier-selection config for the
# running (test) environment (H-9). development's own builders are real,
# directly testable classes instead — see
# spec/services/external_data/synthetic/adapter_builder_spec.rb and
# verifier_builder_spec.rb — since development itself cannot be booted in
# this sandbox (no development.key).
RSpec.describe 'ExternalData adapter and verifier selection' do
  let(:game) { create(:game) }

  describe 'the configured adapter_builder' do
    subject(:adapter_builder) { Rails.application.config.x.external_data.adapter_builder }

    it 'keeps test on the real adapter classes: it yields the registered-adapter block' do
      registered = instance_double(ExternalData::Pokemon::Tcg::Adapter)

      expect(adapter_builder.call(game:) { registered }).to equal(registered)
    end
  end

  describe 'the configured verifier_builder' do
    subject(:verifier_builder) { Rails.application.config.x.external_data.verifier_builder }

    it 'keeps test on the real verifier: it yields the registered-verifier block' do
      registered = ->(_tournament_id) {}

      expect(verifier_builder.call(game:) { registered }).to equal(registered)
    end

    it 'yields nil through unchanged, for a game with no registered verifier' do
      expect(verifier_builder.call(game:) { nil }).to be_nil
    end
  end
end
