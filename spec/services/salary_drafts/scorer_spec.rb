require 'rails_helper'

module SalaryDrafts

  RSpec.describe Scorer do
    let(:game) { create(:game) }
    let(:season) { create(:season, game:, start_date: 1.year.ago.to_date, end_date: 1.year.from_now.to_date) }
    let(:field_size) { 100 }
    let(:tournament) { create(:tournament, game:, starting_date: 2.days.ago, field_size:) }
    let(:draft) { create(:salary_draft, tournament:) }
    let(:participation) { create(:participation, draft:) }
    let(:roster) { create(:roster, participation:) }
    let(:players) { create_list(:player, 2, game:) }

    def result_for(player:, placement:, in_tournament: tournament)
      create(:result, player:, tournament: in_tournament, placement:)
    end

    before do
      season
      roster.players << players
    end

    it 'sums the placement points of all roster players' do
      first, second = players
      result_for(player: first, placement: 1)
      result_for(player: second, placement: 2)

      described_class.call(participation:, draft:)

      expect(participation.reload.score).to eq(165)
    end

    it 'gives a roster player without a result no points' do
      result_for(player: players.first, placement: 1)

      described_class.call(participation:, draft:)

      expect(participation.reload.score).to eq(100)
    end

    it 'ignores a result in another tournament' do
      other_tournament = create(:tournament, game:, starting_date: 20.days.ago, field_size: 100)
      result_for(player: players.first, placement: 1, in_tournament: other_tournament)

      described_class.call(participation:, draft:)

      expect(participation.reload.score).to eq(0)
    end

    describe 'when the tournament has a larger field' do
      let(:field_size) { 600 }

      it 'weights the placement by the field size' do
        result_for(player: players.first, placement: 1)

        described_class.call(participation:, draft:)

        expect(participation.reload.score).to eq(200)
      end
    end

    describe 'when the tournament took place in a past season' do
      let(:tournament) { create(:tournament, game:, starting_date: Date.new(2025, 3, 1), field_size:) }

      before do
        past_season = create(:season, game:, start_date: Date.new(2024, 9, 1), end_date: Date.new(2025, 8, 31))
        create(:setting, season: past_season, settings: { 'scoring' => { 'base_points' => 200 } })
      end

      it 'builds the strategy from the season of the tournament, not the current one' do
        result_for(player: players.first, placement: 1)

        described_class.call(participation:, draft:)

        expect(participation.reload.score).to eq(200)
      end
    end

    it 'scores with an injected strategy' do
      fake_strategy_class = Struct.new(:points) do
        def for(**)
          self
        end

        def points_for(**)
          points
        end
      end
      result_for(player: players.first, placement: 1)

      described_class.call(participation:, draft:, strategy_class: fake_strategy_class.new(7))

      expect(participation.reload.score).to eq(7)
    end

    describe 'when a roster player was suppressed after being drafted' do
      let(:suppressed_player) { create(:player, :without_scores, :suppressed, game:) }

      before { roster.players << suppressed_player }

      it 'still scores that player like any other roster player' do
        result_for(player: suppressed_player, placement: 1)

        described_class.call(participation:, draft:)

        expect(participation.reload.score).to eq(100)
      end
    end

    describe 'when no season covers the tournament' do
      let(:tournament) { create(:tournament, game:, starting_date: 5.years.ago, field_size:) }

      it 'raises Scoring::MissingSeasonError' do
        result_for(player: players.first, placement: 1)

        expect { described_class.call(participation:, draft:) }.to raise_error(Scoring::MissingSeasonError)
      end
    end
  end

end
