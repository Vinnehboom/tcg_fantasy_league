require 'rails_helper'

module ExternalData

  module Synthetic

    RSpec.describe ImportPlayersJob do
      let(:game) { create(:game) }
      let(:season) { create(:season, game:) }
      let(:shape) do
        ExternalData::Synthetic::Shape.new(
          score_range: (200..1600), score_curve: ExternalData::Synthetic::ScoreCurves::LADDER,
          player_count: 5, tournament_count: 2
        )
      end

      before { season }

      it { is_expected.to respond_to(:perform) }

      it 'creates exactly one ExternalRequest row per run' do
        expect do
          described_class.perform_now(game_id: game.id, seed: 1, shape:)
        end.to change(ExternalRequest, :count).by(1)
      end

      it 'imports the requested number of players' do
        described_class.perform_now(game_id: game.id, seed: 1, shape:)

        expect(::Player.where(game:).count).to eq(5)
      end

      it 'records the fetch against the players kind' do
        described_class.perform_now(game_id: game.id, seed: 1, shape:)

        expect(ExternalRequest.last.kind).to eq('players')
      end

      it 'always uses the synthetic adapter, ignoring the configured adapter_builder (Decisions D13)' do
        previous_builder = Rails.application.config.x.external_data.adapter_builder
        Rails.application.config.x.external_data.adapter_builder = lambda do |**|
          raise 'a demo composition root must never read adapter_builder'
        end

        expect { described_class.perform_now(game_id: game.id, seed: 1, shape:) }.not_to raise_error
      ensure
        Rails.application.config.x.external_data.adapter_builder = previous_builder
      end
    end

  end

end
