require 'rails_helper'

RSpec.describe ExternalData::Synthetic::VerifierBuilder do
  subject(:builder) { described_class.new }

  describe 'for a game with a registered verifier' do
    it 'returns the synthetic verifier instead' do
      registered = Game::PTCG_RESULTS_VERIFIER

      expect(builder.call(game: nil) { registered }).to be_a(ExternalData::Synthetic::ResultsVerifier)
    end

    it 'never invokes the registered verifier itself, so no live HTTP call happens' do
      registered = ->(_tournament_id) { raise 'the registered verifier must not be called' }

      expect { builder.call(game: nil) { registered } }.not_to raise_error
    end
  end

  describe 'for a game with no registered verifier' do
    it 'stays nil, honest that no verifier is available — matches test, staging and production' do
      expect(builder.call(game: nil) { nil }).to be_nil
    end
  end
end
