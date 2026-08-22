require 'rails_helper'

RSpec.describe Tournament do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_presence_of(:starting_date) }
  it { is_expected.to have_many(:salary_drafts) }
  it { is_expected.to have_many(:results) }
  it { is_expected.to have_many(:external_requests).dependent(:nullify) }

  it { is_expected.to belong_to(:game) }

  describe '#field_size' do
    describe 'when absent' do
      it 'is a valid tournament' do
        tournament = build(:tournament, field_size: nil)

        expect(tournament).to be_valid
      end
    end

    describe 'when a positive number' do
      it 'is a valid tournament' do
        tournament = build(:tournament, field_size: 128)

        expect(tournament).to be_valid
      end
    end

    describe 'when zero' do
      it 'is not a valid tournament' do
        tournament = build(:tournament, field_size: 0)

        expect(tournament).not_to be_valid
      end
    end

    describe 'when negative' do
      it 'is not a valid tournament' do
        tournament = build(:tournament, field_size: -1)

        expect(tournament).not_to be_valid
      end
    end
  end

  describe '#labs_tournament_id' do
    describe 'when absent' do
      it 'is a valid tournament' do
        tournament = build(:tournament, labs_tournament_id: nil)

        expect(tournament).to be_valid
      end
    end

    describe 'when set to a value not used by any other tournament' do
      it 'is a valid tournament' do
        tournament = build(:tournament, labs_tournament_id: '0070')

        expect(tournament).to be_valid
      end
    end

    describe 'when another tournament already has the same value' do
      it 'is not a valid tournament' do
        create(:tournament, labs_tournament_id: '0070')
        tournament = build(:tournament, labs_tournament_id: '0070')

        expect(tournament).not_to be_valid
      end
    end
  end
end
