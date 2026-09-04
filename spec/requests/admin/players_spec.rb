require 'rails_helper'

module Admin

  RSpec.describe 'Players' do
    let(:admin) { create(:user, :with_role, role: :admin) }
    let(:game_a) { create(:game, id: 'AAAA', name: 'Aaa Game') }
    let(:game_b) { create(:game, id: 'BBBB', name: 'Bbb Game') }

    before do
      sign_in admin
    end

    def rendered_page
      Capybara.string(response.body)
    end

    def attach_select(player_season)
      rendered_page.find(:select, "player_season_modifier_score_modifier_id_#{player_season.id}")
    end

    describe '#index' do
      it 'renders the index template' do
        get admin_players_path

        expect(response).to render_template('admin/players/index')
      end

      context 'when players exist' do
        it "lists each player's name, linked to its show page" do
          player = create(:player, name: 'Ash Ketchum')

          get admin_players_path

          expect(response.body).to include('Ash Ketchum')
          expect(response.body).to include(admin_player_path(player))
        end
      end

      context 'when there are no games at all' do
        it 'renders an empty state' do
          get admin_players_path

          expect(response.body).to include('No players found yet.')
        end
      end

      context 'when a game param is given' do
        it "shows only that game's players" do
          player_a = create(:player, game: game_a, name: 'Ash Ketchum')
          player_b = create(:player, game: game_b, name: 'Misty Waterflower')

          get admin_players_path(game: game_b.id)

          expect(response.body).to include(player_b.name)
          expect(response.body).not_to include(player_a.name)
        end
      end

      context 'when the game param names a game that does not exist' do
        it 'falls back to the alphabetically first game' do
          player_a = create(:player, game: game_a, name: 'Ash Ketchum')
          player_b = create(:player, game: game_b, name: 'Misty Waterflower')

          get admin_players_path(game: 'ZZZZ')

          expect(response.body).to include(player_a.name)
          expect(response.body).not_to include(player_b.name)
        end
      end

      context 'when loading the per-game tab list' do
        it 'shows a tab for every game' do
          game_a
          game_b

          get admin_players_path(game: game_a.id)

          expect(response.body).to include(game_a.name)
          expect(response.body).to include(game_b.name)
        end

        it 'marks the current tab active' do
          game_a
          game_b

          get admin_players_path(game: game_b.id)

          expect(rendered_page).to have_css('a.nav-link.active', exact_text: game_b.name)
          expect(rendered_page).to have_no_css('a.nav-link.active', exact_text: game_a.name)
        end
      end
    end

    describe '#show' do
      it 'renders the show template' do
        get admin_player_path(create(:player))

        expect(response).to render_template('admin/players/show')
      end

      context 'when the player does not exist' do
        it 'returns 404' do
          get admin_player_path(0)

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when the player has more than one season' do
        it 'gives each season its own attach-form field ids' do
          create(:multiplier)
          player = create(:player)
          other_season = create(:season, game: player.game, label: '2025',
                                         start_date: Date.new(2024, 9, 1), end_date: Date.new(2025, 8, 31))
          create(:player_season, player:, season: other_season)

          get admin_player_path(player)

          field_ids = response.body.scan(/id="player_season_modifier_player_season_id_\d+"/)
          expect(field_ids.size).to eq(2)
          expect(field_ids.uniq.size).to eq(2)
        end
      end

      context 'when a player_season has an attached modifier' do
        it 'lists the modifier' do
          score_modifier = create(:multiplier, name: 'hot streak')
          player = create(:player)
          player_season = player.player_seasons.first
          create(:player_season_modifier, player_season:, score_modifier:)

          get admin_player_path(player)

          expect(response.body).to include('hot streak')
        end

        it "leaves it off that season's attach options, since attaching it again would fail" do
          score_modifier = create(:multiplier, name: 'hot streak')
          create(:bonus, name: 'winner') # something else stays available, so the select still renders
          player = create(:player)
          player_season = player.player_seasons.first
          create(:player_season_modifier, player_season:, score_modifier:)

          get admin_player_path(player)

          expect(attach_select(player_season)).to have_no_css('option', text: 'hot streak')
        end

        it "still offers it on a season that doesn't have it yet" do
          score_modifier = create(:multiplier, name: 'hot streak')
          player = create(:player)
          attached_season = player.player_seasons.first
          create(:player_season_modifier, player_season: attached_season, score_modifier:)
          other_season = create(:season, game: player.game, label: '2025',
                                         start_date: Date.new(2024, 9, 1), end_date: Date.new(2025, 8, 31))
          bare_player_season = create(:player_season, player:, season: other_season)

          get admin_player_path(player)

          expect(attach_select(bare_player_season)).to have_css('option', text: 'hot streak')
        end

        context 'when the season already has every kept score modifier' do
          it 'shows a message instead of an empty attach form' do
            only_score_modifier = create(:multiplier, name: 'hot streak')
            player = create(:player)
            player_season = player.player_seasons.first
            create(:player_season_modifier, player_season:, score_modifier: only_score_modifier)

            get admin_player_path(player)

            expect(response.body).to include('This season already has every score modifier there is.')
            expect(rendered_page).to have_no_css('select',
                                                 id: "player_season_modifier_score_modifier_id_#{player_season.id}")
          end
        end
      end

      context 'when a player_season has an attached modifier that has since been discarded' do
        it 'renders the page instead of raising, still showing the modifier by name' do
          score_modifier = create(:multiplier, name: 'legend')
          player = create(:player)
          player_season = player.player_seasons.first
          create(:player_season_modifier, player_season:, score_modifier:)
          score_modifier.discard

          get admin_player_path(player)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('legend')
        end
      end
    end

    context 'when the visitor is not an admin' do
      it 'refuses the list' do
        sign_in create(:user)

        get admin_players_path

        expect(response).to redirect_to(root_path)
      end

      it 'refuses the show page' do
        sign_in create(:user)

        get admin_player_path(create(:player))

        expect(response).to redirect_to(root_path)
      end
    end
  end

end
