require 'rails_helper'

module Players

  RSpec.describe SeasonStats do
    let(:game) { create(:game) }

    describe '#average' do
      it 'returns the arithmetic mean of the season scores' do
        player_one = create(:player, :without_scores, game:)
        player_two = create(:player, :without_scores, game:)
        create(:external_score, player: player_one, season: '2026', score: 10)
        create(:external_score, player: player_two, season: '2026', score: 20)

        average = described_class.new(game:, season: '2026').average

        expect(average).to eq(15.0)
      end

      it 'returns nil when the season holds no scores' do
        average = described_class.new(game:, season: '2026').average

        expect(average).to be_nil
      end

      it 'ignores scores that carry another season label' do
        player = create(:player, :without_scores, game:)
        create(:external_score, player:, season: '2026', score: 10)
        create(:external_score, player:, season: '2025', score: 999)

        average = described_class.new(game:, season: '2026').average

        expect(average).to eq(10.0)
      end

      it 'counts a rescored player one time, with that player newest score' do
        player = create(:player, :without_scores, game:)
        travel_to(2.days.ago) { create(:external_score, player:, season: '2026', score: 10) }
        create(:external_score, player:, season: '2026', score: 20)

        average = described_class.new(game:, season: '2026').average

        expect(average).to eq(20.0)
      end
    end

    describe '#median' do
      it 'returns the middle score of an odd-sized population' do
        players = create_list(:player, 3, :without_scores, game:)
        create(:external_score, player: players[0], season: '2026', score: 10)
        create(:external_score, player: players[1], season: '2026', score: 20)
        create(:external_score, player: players[2], season: '2026', score: 90)

        median = described_class.new(game:, season: '2026').median

        expect(median).to eq(20.0)
      end

      it 'returns the mean of the two middle scores of an even-sized population' do
        players = create_list(:player, 4, :without_scores, game:)
        create(:external_score, player: players[0], season: '2026', score: 10)
        create(:external_score, player: players[1], season: '2026', score: 20)
        create(:external_score, player: players[2], season: '2026', score: 30)
        create(:external_score, player: players[3], season: '2026', score: 90)

        median = described_class.new(game:, season: '2026').median

        expect(median).to eq(25.0)
      end

      it 'returns nil when the season holds no scores' do
        median = described_class.new(game:, season: '2026').median

        expect(median).to be_nil
      end
    end
  end

end
