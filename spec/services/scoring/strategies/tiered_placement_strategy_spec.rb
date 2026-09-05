require 'rails_helper'

RSpec.describe Scoring::Strategies::TieredPlacementStrategy do
  subject(:strategy) { described_class.new }

  # Duck-typed fixtures for #points_for's `result:` argument — a local
  # Struct rather than a double/OpenStruct, per the style guide.
  let(:tournament_fixture) { Struct.new(:field_size) }
  let(:result_fixture) { Struct.new(:placement, :tournament) }

  it_behaves_like 'a Scoring::Strategy'

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

    context 'when placement is 1st, across the M and L size classes' do
      let(:placement) { 1 }

      where(:field_size, :expected_points) do
        [
          [1000, 200], # M: multiplier x2
          [2000, 400]  # L: multiplier x4
        ]
      end

      with_them do
        it { is_expected.to eq(expected_points) }
      end
    end

    context 'when the tournament has no field_size on record' do
      let(:placement) { 1 }
      let(:field_size) { nil }

      it 'raises MissingFieldSizeError' do
        expect { points_for }.to raise_error(Scoring::MissingFieldSizeError)
      end
    end

    context 'when configured size classes have no band covering a smaller field_size' do
      subject(:strategy) do
        described_class.new(size_classes: [{ minimum_field_size: 500, multiplier: 2, max_tier_field_size: 999 }])
      end

      let(:placement) { 1 }
      let(:field_size) { 100 }

      it 'falls back to the lowest configured band instead of raising' do
        expect(points_for).to eq(200) # base_score 100 * the only (lowest) band's multiplier 2
      end
    end
  end

  describe 'monotonicity in field_size for the default config (the ticket done-criterion)' do
    # A wide spread crossing every size-class boundary (499/500,
    # 1499/1500, 2999/3000) and a range of placements from 1st to deep
    # in a large field — not just the one field_size the worked example
    # pins. Regression coverage for the bug the reviewer found: a fixed
    # placement scoring FEWER points in a larger field, because an
    # earlier version derived max_tier from raw field_size instead of
    # from the size class.
    let(:field_sizes) do
      [1, 2, 4, 8, 50, 100, 499, 500, 501, 999, 1000, 1400, 1499,
       1500, 1501, 2000, 2999, 3000, 3001, 5000, 10_000, 50_000]
    end
    let(:placements) { [1, 2, 3, 4, 8, 16, 64, 100, 512, 600, 1000, 1024, 2500, 3000] }

    it 'never awards fewer points for a larger field at the same placement, for any placement in the spread' do
      violations = placements.filter_map do |placement|
        points_by_field_size = field_sizes.map do |field_size|
          result = result_fixture.new(placement, tournament_fixture.new(field_size))
          strategy.points_for(result:)
        end

        next if points_by_field_size == points_by_field_size.sort

        "placement #{placement}: #{field_sizes.zip(points_by_field_size)}"
      end

      expect(violations).to be_empty
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

    context 'when the season has an unparseable value but the game has a valid default for that key' do
      before do
        create(:setting, :for_game, settingable: game, settings: { 'scoring' => { 'decay' => 0.5 } })
        create(:setting, season:, settings: { 'scoring' => { 'decay' => 'half' } })
      end

      it "falls through to the game's default, not the code constant, per D5's resolution order" do
        expect(strategy_for.base_score(placement: 2, field_size: 3000)).to eq(50) # 100 * 0.5**1, not 100 * 0.65**1
      end
    end

    context 'when the settings payload holds a decay above 1' do
      before do
        create(:setting, season:, settings: { 'scoring' => { 'base_points' => 100, 'decay' => 5.0 } })
      end

      it 'clamps decay to 1.0 rather than letting points grow with tier depth' do
        expect(strategy_for.base_score(placement: 8, field_size: 3000)).to eq(100) # 100 * 1.0**3, not 100 * 5.0**3
      end
    end

    context 'when a configured size class has a negative multiplier' do
      before do
        create(:setting, season:, settings: {
          'scoring' => {
            'size_classes' => [{ 'minimum_field_size' => 0, 'multiplier' => -5, 'max_tier_field_size' => 3000 }]
          }
        })
      end

      it 'clamps the multiplier to a positive minimum rather than scoring negative points' do
        field_size = 3000
        result = result_fixture.new(1, tournament_fixture.new(field_size))

        expect(strategy_for.points_for(result:)).to eq(100) # base_score 100 * multiplier clamped to 1, not -5
      end
    end

    context "when the settings payload's size_classes isn't an array" do
      before do
        create(:setting, season:, settings: { 'scoring' => { 'size_classes' => { 'not' => 'an array' } } })
      end

      it 'falls back to the code default size classes instead of raising' do
        field_size = 3000
        result = result_fixture.new(1, tournament_fixture.new(field_size))

        expect(strategy_for.points_for(result:)).to eq(800) # base_score 100 * DEFAULT_SIZE_CLASSES' XL multiplier 8
      end
    end

    context 'when the settings payload has a partially-invalid size_classes list' do
      before do
        create(:setting, season:, settings: {
          'scoring' => {
            'size_classes' => [
              { 'minimum_field_size' => 0, 'multiplier' => 1, 'max_tier_field_size' => 100 },
              { 'minimum_field_size' => 500 } # missing multiplier and max_tier_field_size
            ]
          }
        })
      end

      it 'drops only the band that fails to parse, keeping the valid one' do
        field_size = 3000
        result = result_fixture.new(1, tournament_fixture.new(field_size))

        expect(strategy_for.points_for(result:)).to eq(100) # only the S-shaped band survives
      end
    end

    context 'when every band in the settings payload fails to parse, and the game has a valid default list' do
      before do
        create(:setting, :for_game, settingable: game, settings: {
          'scoring' => {
            'size_classes' => [{ 'minimum_field_size' => 0, 'multiplier' => 7, 'max_tier_field_size' => 3000 }]
          }
        })
        create(:setting, season:,
                         settings: { 'scoring' => { 'size_classes' => [{ 'minimum_field_size' => 'nope' }] } })
      end

      it "falls through to the game's default size classes, not straight to the code default" do
        field_size = 3000
        result = result_fixture.new(1, tournament_fixture.new(field_size))

        expect(strategy_for.points_for(result:)).to eq(700) # base_score 100 * the game default's multiplier 7
      end
    end

    context 'when the settings payload overrides size_classes' do
      before do
        create(:setting, season:, settings: {
          'scoring' => {
            'size_classes' => [{ 'minimum_field_size' => 0, 'multiplier' => 99, 'max_tier_field_size' => 3000 }]
          }
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
