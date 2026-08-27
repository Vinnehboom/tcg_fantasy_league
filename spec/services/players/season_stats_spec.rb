require 'rails_helper'

module Players

  RSpec.describe SeasonStats do
    let(:game) { create(:game) }

    describe '#average' do
      it 'returns the arithmetic mean of the season scores' do
        player_one = create(:player, :without_scores, game:)
        player_two = create(:player, :without_scores, game:)
        create(:external_score, player: player_one, season: '2026', score: 10)
        create(:external_score, player: player_two, season: '2026', score: 15)

        average = described_class.new(game:, season_label: '2026').average

        expect(average).to eq(12.5)
      end

      context 'when the season holds no scores' do
        it 'returns nil' do
          average = described_class.new(game:, season_label: '2026').average

          expect(average).to be_nil
        end
      end

      context 'when scores carry another season label' do
        it 'ignores them' do
          player = create(:player, :without_scores, game:)
          create(:external_score, player:, season: '2026', score: 10)
          create(:external_score, player:, season: '2025', score: 999)

          average = described_class.new(game:, season_label: '2026').average

          expect(average).to eq(10.0)
        end
      end

      context 'when a player was rescored' do
        it "counts them one time, with that player's newest score" do
          player = create(:player, :without_scores, game:)
          travel_to(2.days.ago) { create(:external_score, player:, season: '2026', score: 10) }
          create(:external_score, player:, season: '2026', score: 20)

          average = described_class.new(game:, season_label: '2026').average

          expect(average).to eq(20.0)
        end
      end

      context 'when scores come from more than one game' do
        it 'only reflects scores from the requested game' do
          game_a = create(:game)
          game_b = create(:game)
          player_a = create(:player, :without_scores, game: game_a)
          player_b = create(:player, :without_scores, game: game_b)
          create(:external_score, player: player_a, season: '2026', score: 10)
          create(:external_score, player: player_b, season: '2026', score: 90)

          average = described_class.new(game: game_a, season_label: '2026').average

          expect(average).to eq(10.0)
        end
      end
    end

    describe '#median' do
      context 'with an odd-sized population' do
        it 'returns the middle score, as a Float' do
          players = create_list(:player, 3, :without_scores, game:)
          create(:external_score, player: players[0], season: '2026', score: 10)
          create(:external_score, player: players[1], season: '2026', score: 20)
          create(:external_score, player: players[2], season: '2026', score: 90)

          median = described_class.new(game:, season_label: '2026').median

          expect(median).to eql(20.0) # rubocop:disable RSpec/BeEql -- pins Float, not object identity
        end
      end

      context 'with an even-sized population' do
        it 'returns the mean of the two middle scores' do
          players = create_list(:player, 4, :without_scores, game:)
          create(:external_score, player: players[0], season: '2026', score: 10)
          create(:external_score, player: players[1], season: '2026', score: 20)
          create(:external_score, player: players[2], season: '2026', score: 31)
          create(:external_score, player: players[3], season: '2026', score: 90)

          median = described_class.new(game:, season_label: '2026').median

          expect(median).to eq(25.5)
        end
      end

      context 'when the season holds no scores' do
        it 'returns nil' do
          median = described_class.new(game:, season_label: '2026').median

          expect(median).to be_nil
        end
      end
    end
  end

end
