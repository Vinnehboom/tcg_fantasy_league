require 'rails_helper'

module ExternalData

  module Synthetic

    RSpec.describe ImportResultsJob do
      let(:game) { create(:game) }
      let(:season) { create(:season, game:) }
      let(:shape) do
        ExternalData::Synthetic::Shape.new(
          score_range: (200..1600), score_curve: ExternalData::Synthetic::ScoreCurves::LADDER,
          player_count: 6, tournament_count: 1
        )
      end
      let(:tournament) { create(:tournament, game:, external_id: '/tournaments/past-1') }

      before do
        season
        ImportPlayersJob.perform_now(game_id: game.id, seed: 3, shape:)
      end

      it { is_expected.to respond_to(:perform) }

      it 'creates exactly one ExternalRequest row per run' do
        expect do
          described_class.perform_now(tournament_id: tournament.id, seed: 3, shape:)
        end.to change(ExternalRequest, :count).by(1)
      end

      it 'imports the fetched results as Result rows' do
        expect do
          described_class.perform_now(tournament_id: tournament.id, seed: 3, shape:)
        end.to change(::Result, :count)
      end

      it 'names only players the players import already created, per the same seed and shape (Decisions D8)' do
        expect do
          described_class.perform_now(tournament_id: tournament.id, seed: 3, shape:)
        end.not_to change(::Player, :count)
      end

      it 'links the ExternalRequest to the tournament it ran for' do
        described_class.perform_now(tournament_id: tournament.id, seed: 3, shape:)

        expect(ExternalRequest.last.requestable).to eq(tournament)
      end

      it "sets the tournament's field_size from the adapter" do
        described_class.perform_now(tournament_id: tournament.id, seed: 3, shape:)

        expect(tournament.reload.field_size).to be_positive
      end
    end

  end

end
