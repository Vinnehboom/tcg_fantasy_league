require 'rails_helper'

RSpec.describe ExternalData::Synthetic::Adapter do
  subject(:adapter) { described_class.new(game:) }

  let(:game) { create(:game) }

  def shape_for(score_range:, score_curve:, player_count: 50, tournament_count: 3)
    Demo::Shape.new(score_range:, score_curve:, player_count:, tournament_count:)
  end

  it_behaves_like 'an external data adapter'

  describe 'the production guard' do
    context 'when Rails.env is production' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production')) }

      it 'raises instead of returning a usable adapter' do
        expect { described_class.new(game:) }.to raise_error(ExternalData::Exception, /must never run/)
      end
    end

    context 'when Rails.env is not production' do
      it 'does not raise' do
        expect { described_class.new(game:) }.not_to raise_error
      end
    end
  end

  describe 'determinism' do
    it 'returns identical players for the same seed' do
      first = described_class.new(game:, seed: 42).players.map(&:instance_values)
      second = described_class.new(game:, seed: 42).players.map(&:instance_values)

      expect(first).to eq(second)
    end

    it 'returns different players for a different seed' do
      first = described_class.new(game:, seed: 42).players.map(&:instance_values)
      second = described_class.new(game:, seed: 43).players.map(&:instance_values)

      expect(first).not_to eq(second)
    end

    it 'restores Faker::Config.random afterward, since it is a sticky thread-local' do
      previous = Random.new(7)
      Faker::Config.random = previous

      adapter.players

      expect(Faker::Config.random).to equal(previous)
    end
  end

  describe '#players' do
    it 'returns the requested number of players' do
      shape = shape_for(score_range: (200..1600), score_curve: Demo::Curves::LADDER,
                        player_count: 10)

      expect(described_class.new(game:, shape:).players.length).to eq(10)
    end

    it 'tags every player with the given season' do
      season = create(:season, game:)

      players = described_class.new(game:, season:).players

      expect(players.map(&:season).uniq).to eq([season])
    end

    it 'places the ladder-shaped median well below the band midpoint' do
      shape = shape_for(score_range: (200..1600), score_curve: Demo::Curves::LADDER)
      sorted_scores = described_class.new(game:, shape:).players.map(&:external_points).sort

      expect(sorted_scores[sorted_scores.length / 2]).to be < 900
    end

    it 'concentrates the ELO-band-shaped middle half of the field within the middle of the band' do
      shape = shape_for(score_range: (1000..1600), score_curve: Demo::Curves::ELO_BAND)
      sorted_scores = described_class.new(game:, shape:).players.map(&:external_points).sort
      middle_half = sorted_scores[(sorted_scores.length / 4)..(sorted_scores.length * 3 / 4)]

      expect(middle_half).to all(be_between(1150, 1450))
    end
  end

  describe '#upcoming_tournaments' do
    it 'returns the requested number of tournaments' do
      shape = shape_for(score_range: (200..1600), score_curve: Demo::Curves::LADDER,
                        tournament_count: 5)

      expect(described_class.new(game:, shape:).upcoming_tournaments.length).to eq(5)
    end

    it 'never returns a date less than 7 days out' do
      dates = adapter.upcoming_tournaments.map(&:starting_date)

      expect(dates).to all(be >= 7.days.from_now.to_date)
    end
  end

  describe '#results' do
    let(:tournament) { build(:tournament, external_id: '/tournaments/0') }

    it 'names only players the adapter itself would generate for the same seed and player count' do
      shape = shape_for(score_range: (200..1600), score_curve: Demo::Curves::LADDER,
                        player_count: 20)
      generated_ids = described_class.new(game:, shape:).players.map(&:external_id)
      result_ids = described_class.new(game:, shape:).results(tournament:).map(&:player_external_id)

      expect(result_ids - generated_ids).to be_empty
    end

    it 'answers for a tournament the adapter did not itself generate' do
      unknown_tournament = build(:tournament, external_id: '/tournaments/never-seen')

      expect(adapter.results(tournament: unknown_tournament)).not_to be_empty
    end

    it 'assigns a distinct placement to every result' do
      placements = adapter.results(tournament:).map(&:placement)

      expect(placements).to match_array(placements.uniq)
    end
  end

  describe '#field_size' do
    it 'returns a positive integer above the number of results returned for the same tournament' do
      tournament = build(:tournament, external_id: '/tournaments/1')

      expect(adapter.field_size(tournament:)).to be > adapter.results(tournament:).length
    end
  end
end
