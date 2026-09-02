require 'rails_helper'

module Players

  RSpec.describe SeasonStats do
    let(:game) { create(:game) }
    let(:season) { create(:season, game:, label: '2026') }

    def create_score(player:, season:, score:)
      player_season = player.player_seasons.find_or_create_by!(season:)
      create(:external_score, player_season:, score:)
    end

    describe '#average' do
      it 'returns the arithmetic mean of the season scores' do
        player_one = create(:player, :without_scores, game:)
        player_two = create(:player, :without_scores, game:)
        create_score(player: player_one, season:, score: 10)
        create_score(player: player_two, season:, score: 15)

        average = described_class.new(game:, season:).average

        expect(average).to eq(12.5)
      end

      context 'when the season holds no scores' do
        it 'returns nil' do
          average = described_class.new(game:, season:).average

          expect(average).to be_nil
        end
      end

      context 'when scores carry another season' do
        it 'ignores them' do
          other_season = create(:season, game:, label: '2025', start_date: 2.years.ago, end_date: 13.months.ago)
          player = create(:player, :without_scores, game:)
          create_score(player:, season:, score: 10)
          create_score(player:, season: other_season, score: 999)

          average = described_class.new(game:, season:).average

          expect(average).to eq(10.0)
        end
      end

      context 'when a player was rescored' do
        it "counts them one time, with that player's newest score" do
          player = create(:player, :without_scores, game:)
          create_score(player:, season:, score: 20)
          travel_to(2.days.ago) { create_score(player:, season:, score: 10) }

          average = described_class.new(game:, season:).average

          expect(average).to eq(20.0)
        end
      end

      context 'when scores come from more than one game' do
        it 'only reflects scores from the requested game' do
          other_game = create(:game)
          other_game_season = create(:season, game: other_game, label: '2026')
          player = create(:player, :without_scores, game:)
          other_player = create(:player, :without_scores, game: other_game)
          create_score(player:, season:, score: 10)
          create_score(player: other_player, season: other_game_season, score: 90)

          average = described_class.new(game:, season:).average

          expect(average).to eq(10.0)
        end
      end
    end

    describe '#median' do
      context 'with an odd-sized population' do
        it 'returns the middle score, as a Float' do
          players = create_list(:player, 3, :without_scores, game:)
          [90, 10, 20].each.with_index { |score, i| create_score(player: players[i], season:, score:) }

          median = described_class.new(game:, season:).median

          expect(median).to be_a(Float).and eq(20.0)
        end
      end

      context 'with an even-sized population' do
        it 'returns the mean of the two middle scores' do
          players = create_list(:player, 4, :without_scores, game:)
          [90, 31, 10, 20].each.with_index { |score, i| create_score(player: players[i], season:, score:) }

          median = described_class.new(game:, season:).median

          expect(median).to eq(25.5)
        end
      end

      context 'when the season holds no scores' do
        it 'returns nil' do
          median = described_class.new(game:, season:).median

          expect(median).to be_nil
        end
      end
    end
  end

end
