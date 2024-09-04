require 'rails_helper'

RSpec.describe 'Rosters' do
  let!(:game) { create(:game, id: 'PTCG') }
  let(:user) { create(:user) }
  let(:admin) { create(:user, :with_role, role: :admin) }
  let(:roster_size) { 2 }
  let(:participation) { create(:participation, user:, draft: create(:salary_draft, roster_size:)) }

  before do
    sign_in user
  end

  describe '#show' do
    let(:roster) { create(:roster, participation:) }

    it 'shows the roster' do
      get game_roster_path(roster, game:)
      expect(response).to render_template('rosters/show')
    end
  end

  describe '#create' do
    before do
      sign_in user
    end

    describe 'when the information is complete' do
      let(:params) do
        {
          roster: {
            participation_id: participation.id
          }
        }
      end

      it 'adds the roster to the platform' do
        expect { post game_rosters_path(game:), params: }.to change(Roster, :count).by(1)
      end

      it 'show the new roster' do
        post(game_rosters_path(game:), params:)
        roster = Roster.last
        expect(response).to redirect_to(game_roster_path(id: roster.id, game:))
      end
    end
  end

  describe '#edit' do
    before do
      sign_in user
    end

    let(:roster) { create(:roster, participation:) }

    it 'shows the roster form' do
      get edit_game_roster_path(roster, game:)
      expect(response).to render_template('rosters/edit')
    end
  end

  describe '#update' do
    let!(:roster) { create(:roster, participation:) }
    let(:player) { create(:player, game:) }

    before do
      sign_in user
    end

    context 'when adding a player' do
      let(:params) do
        {
          roster: {
            roster_players_attributes: [{ player_id: player.id }]
          }
        }
      end

      it 'adds the player to the roster' do
        expect { patch game_roster_path(id: roster.id, game:), params: }.to change(roster.roster_players, :count).by(1)
      end

      context 'when the roster is full' do
        before do
          create_list(:roster_player, roster_size, roster:)
        end

        it 'does not add the player' do
          expect { patch game_roster_path(id: roster.id, game:), params: }.not_to change(roster.roster_players, :count)
        end
      end
    end

    context 'when removing a player' do
      let!(:roster_player) { create(:roster_player, player:, roster:) }

      let(:params) do
        {
          roster: {
            roster_players_attributes: [{ id: roster_player.id, _destroy: '1' }]
          }
        }
      end

      it 'removes the player from the roster roster' do
        expect { patch game_roster_path(id: roster.id, game:), params: }.to change(roster.roster_players, :count).by(-1)
      end
    end
  end

  describe '#destroy' do
    before do
      sign_in user
    end

    let(:roster) { create(:roster, participation:) }

    it 'deletes the roster' do
      delete(game_roster_path(roster, game:))
      expect(Roster.find_by(id: roster.id)).to be_falsey
    end
  end
end
