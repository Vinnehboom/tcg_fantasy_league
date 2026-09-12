require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#player_name_link' do
    context 'when the player is not suppressed' do
      let(:player) { create(:player, name: 'Real Name', external_id: '/players/9') }

      it 'links the real name to the external profile' do
        result = helper.player_name_link(player)

        expect(result).to include('Real Name', player.external_url)
      end

      it 'returns an html-safe value, same as the suppressed branch' do
        expect(helper.player_name_link(player)).to be_html_safe
      end
    end

    context 'when the player is suppressed' do
      let(:player) { create(:player, :suppressed, name: 'Real Name') }

      it 'returns the placeholder with no link' do
        result = helper.player_name_link(player)

        expect(result).to include(I18n.t('players.suppressed_display_name'))
        expect(result).not_to include('<a ')
      end

      it 'never includes the real name' do
        expect(helper.player_name_link(player)).not_to include('Real Name')
      end

      it 'returns an html-safe value, same as the linked branch' do
        expect(helper.player_name_link(player)).to be_html_safe
      end
    end
  end

  describe '#masked_player_cost' do
    context 'when the player is not suppressed' do
      it 'shows the real cost' do
        player = create(:player, :without_scores)
        create(:external_score, player:, score: 500)
        roster_player = create(:roster_player, player:, roster: create(:roster, participation: create(:participation)))

        expect(helper.masked_player_cost(roster_player)).to eq('40.00')
      end
    end

    context 'when the player is suppressed' do
      it 'shows a placeholder instead of the cost' do
        player = create(:player, :without_scores, :suppressed)
        create(:external_score, player:, score: 500)
        roster_player = create(:roster_player, player:, roster: create(:roster, participation: create(:participation)))

        expect(helper.masked_player_cost(roster_player)).to eq('—')
      end
    end
  end
end
