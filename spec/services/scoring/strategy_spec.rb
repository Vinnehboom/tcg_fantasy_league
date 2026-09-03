require 'rails_helper'

module Scoring

  RSpec.describe Strategy do
    subject(:strategy) { described_class.new }

    # Duck-typed fixtures for #points_for's `result:` argument — a local
    # Struct rather than a double/OpenStruct, per the style guide.
    let(:tournament_fixture) { Struct.new(:field_size) }
    let(:result_fixture) { Struct.new(:placement, :tournament) }

    describe '#base_score' do
      context 'with the worked 3000-player (XL) example' do
        where(:placement, :expected_base_score) do
          [
            [1, 100],
            [2, 65],
            [4, 42],
            [8, 27],
            [64, 8],
            [512, 2],
            [1024, 1],
            [2500, 1] # missed the deepest real bracket (max_tier 2048)
          ]
        end

        with_them do
          it { expect(strategy.base_score(placement:, field_size: 3000)).to eq(expected_base_score) }
        end
      end

      context 'when placement is not numerically valid yet (no C-12 validation)' do
        where(:placement, :expected_base_score) do
          [
            [0, 100],
            [-5, 100]
          ]
        end

        with_them do
          it 'clamps to 1st-place tier rather than raising' do
            expect(strategy.base_score(placement:, field_size: 3000)).to eq(expected_base_score)
          end
        end
      end

      context 'when the tournament has no field_size on record' do
        it 'raises MissingFieldSizeError' do
          expect { strategy.base_score(placement: 1, field_size: nil) }
            .to raise_error(Scoring::MissingFieldSizeError)
        end
      end
    end

    describe '#points_for' do
      subject(:points_for) do
        strategy.points_for(result: result_fixture.new(placement, tournament_fixture.new(field_size)))
      end

      context 'with the worked 3000-player (XL) example' do
        let(:field_size) { 3000 }

        where(:placement, :expected_points) do
          [
            [1, 800],
            [2, 520],
            [4, 336],
            [8, 216],
            [64, 64],
            [512, 16],
            [1024, 8],
            [2500, 8] # missed the deepest real bracket (max_tier 2048)
          ]
        end

        with_them do
          it { is_expected.to eq(expected_points) }
        end
      end

      context 'with a small (S) field' do
        let(:placement) { 1 }
        let(:field_size) { 100 }

        it 'applies the S multiplier (x1), not XL' do
          expect(points_for).to eq(100)
        end
      end

      context 'when the tournament has no field_size on record' do
        let(:placement) { 1 }
        let(:field_size) { nil }

        it 'raises MissingFieldSizeError' do
          expect { points_for }.to raise_error(Scoring::MissingFieldSizeError)
        end
      end
    end

    describe '.for' do
      subject(:strategy_for) { described_class.for(season:) }

      let(:game) { create(:game) }
      let(:season) { create(:season, game:) }

      context 'when season is nil' do
        let(:season) { nil }

        it 'raises MissingSeasonError' do
          expect { strategy_for }.to raise_error(Scoring::MissingSeasonError)
        end
      end

      context 'when neither the season nor its game has a Setting row' do
        it 'falls back to the code default base_points' do
          expect(strategy_for.base_score(placement: 1, field_size: 3000)).to eq(100)
        end

        it 'reports it is using default config' do
          expect(strategy_for.using_default_config?).to be(true)
        end
      end

      context "when only the season's game has a default Setting" do
        before do
          create(:setting, :for_game, settingable: game,
                                      settings: { 'scoring' => { 'base_points' => 200, 'decay' => 0.5 } })
        end

        it "uses the game's default values" do
          expect(strategy_for.base_score(placement: 2, field_size: 3000)).to eq(100) # 200 * 0.5**1
        end

        it 'reports it is using default config' do
          expect(strategy_for.using_default_config?).to be(true)
        end
      end

      context 'when the season has its own Setting row' do
        before do
          create(:setting, season:, settings: { 'scoring' => { 'base_points' => 200, 'decay' => 0.5 } })
        end

        it "uses the season's own values" do
          expect(strategy_for.base_score(placement: 2, field_size: 3000)).to eq(100) # 200 * 0.5**1
        end

        it 'reports it is not using default config' do
          expect(strategy_for.using_default_config?).to be(false)
        end
      end

      context 'when the season overrides only one key, per-key merging with the game default' do
        before do
          create(:setting, :for_game, settingable: game,
                                      settings: { 'scoring' => { 'base_points' => 200, 'decay' => 0.5 } })
          create(:setting, season:, settings: { 'scoring' => { 'base_points' => 300 } })
        end

        it "uses the season's override for the key it specifies" do
          strategy = strategy_for

          expect(strategy.base_score(placement: 1, field_size: 3000)).to eq(300)
        end

        it "falls through to the game default for a key the season doesn't specify" do
          strategy = strategy_for

          # base_points 300, decay 0.5 (from the game default, not code's 0.65)
          expect(strategy.base_score(placement: 2, field_size: 3000)).to eq(150)
        end
      end

      context 'when the settings payload holds values that fail to coerce' do
        before do
          create(:setting, season:, settings: { 'scoring' => { 'base_points' => 'not-a-number' } })
        end

        it 'falls back to the code default for the unparseable key' do
          expect(strategy_for.base_score(placement: 1, field_size: 3000)).to eq(100)
        end
      end

      context 'when the settings payload overrides size_classes' do
        before do
          create(:setting, season:, settings: {
            'scoring' => { 'size_classes' => [{ 'minimum_field_size' => 0, 'multiplier' => 99 }] }
          })
        end

        it 'uses the overridden size classes' do
          field_size = 3000
          result = result_fixture.new(1, tournament_fixture.new(field_size))

          expect(strategy_for.points_for(result:)).to eq(9900) # base_score 100 * multiplier 99
        end
      end
    end
  end

end
