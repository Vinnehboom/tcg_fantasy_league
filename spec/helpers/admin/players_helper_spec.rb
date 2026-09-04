require 'rails_helper'

RSpec.describe Admin::PlayersHelper do
  describe '#available_score_modifiers' do
    subject(:available_score_modifiers) { helper.available_score_modifiers(player_season:) }

    let(:player_season) { create(:player_season) }
    let(:attached) { create(:multiplier, name: 'hot streak') }
    let(:unattached) { create(:bonus, name: 'winner') }

    before { create(:player_season_modifier, player_season:, score_modifier: attached) }

    it 'excludes a modifier the player already has for that season' do
      expect(available_score_modifiers).not_to include(attached)
    end

    it "includes a modifier the player doesn't have for that season yet" do
      unattached_score_modifier = unattached

      expect(available_score_modifiers).to include(unattached_score_modifier)
    end

    context 'when a modifier has since been discarded' do
      let(:discarded) { create(:bonus, name: 'legend', discarded_at: Time.current) }

      before { discarded }

      it 'excludes it too' do
        expect(available_score_modifiers).not_to include(discarded)
      end
    end

    context 'when given an explicit pool, as the view actually calls it' do
      subject(:available_score_modifiers) do
        helper.available_score_modifiers(player_season:, kept_score_modifiers: [attached, unattached])
      end

      it 'filters that pool instead of querying for one' do
        expect(available_score_modifiers).to contain_exactly(unattached)
      end
    end
  end
end
