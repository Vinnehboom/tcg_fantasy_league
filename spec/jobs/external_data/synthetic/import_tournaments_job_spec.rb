require 'rails_helper'

module ExternalData

  module Synthetic

    RSpec.describe ImportTournamentsJob do
      let(:game) { create(:game) }
      let(:shape) do
        ExternalData::Synthetic::Shape.new(
          score_range: (200..1600), score_curve: ExternalData::Synthetic::ScoreCurves::LADDER,
          player_count: 4, tournament_count: 3
        )
      end

      it { is_expected.to respond_to(:perform) }

      it 'creates exactly one ExternalRequest row per run' do
        expect do
          described_class.perform_now(game_id: game.id, seed: 5, shape:)
        end.to change(ExternalRequest, :count).by(1)
      end

      it 'imports the requested number of upcoming tournaments' do
        described_class.perform_now(game_id: game.id, seed: 5, shape:)

        expect(::Tournament.where(game:).count).to eq(3)
      end

      it 'records the fetch against the tournaments kind' do
        described_class.perform_now(game_id: game.id, seed: 5, shape:)

        expect(ExternalRequest.last.kind).to eq('tournaments')
      end

      it 'imports only tournaments at least 7 days out' do
        described_class.perform_now(game_id: game.id, seed: 5, shape:)

        expect(::Tournament.where(game:).pluck(:starting_date)).to all(be >= 7.days.from_now.to_date)
      end
    end

  end

end
