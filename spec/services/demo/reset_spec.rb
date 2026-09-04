require 'rails_helper'

RSpec.describe Demo::Reset do
  describe '.call' do
    context 'when not confirmed' do
      it 'raises instead of truncating anything' do
        create(:game)

        expect { described_class.call(confirm: false) }.to raise_error(ExternalData::Exception, /confirmation/)
        expect(Game.count).to eq(1)
      end
    end

    context 'when confirmed, in an allowed environment' do
      it 'erases every application table' do
        create(:game)
        create(:user)

        described_class.call(confirm: true)

        expect(Game.count).to eq(0)
        expect(User.count).to eq(0)
      end

      it 'leaves the schema itself untouched, so a later create still works' do
        described_class.call(confirm: true)

        expect { create(:game) }.not_to raise_error
      end
    end

    context 'when Rails.env is not development or test' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('staging')) }

      it 'raises instead of truncating anything, even when confirmed' do
        create(:game)

        expect { described_class.call(confirm: true) }.to raise_error(ExternalData::Exception, /only runs in/)
        expect(Game.count).to eq(1)
      end
    end
  end
end
