require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#player_name_link' do
    context 'when the player is not suppressed' do
      let(:player) { create(:player, name: 'Real Name', external_id: '/players/9') }

      it 'links the real name to the external profile' do
        result = helper.player_name_link(player)

        expect(result).to include('Real Name', player.external_url)
      end
    end

    context 'when the player is suppressed' do
      let(:player) { create(:player, :suppressed, name: 'Real Name') }

      it 'returns the placeholder with no link' do
        result = helper.player_name_link(player)

        expect(result).to eq(I18n.t('players.suppressed_display_name'))
      end

      it 'never includes the real name' do
        expect(helper.player_name_link(player)).not_to include('Real Name')
      end
    end
  end
end
