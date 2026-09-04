require 'rails_helper'

RSpec.describe Admin::ScoreModifiersHelper do
  describe '#score_modifier_name_label' do
    subject { helper.score_modifier_name_label('hot streak') }

    it { is_expected.to eq('hot streak') }

    it 'looks up the translation instead of just echoing the value it was given' do
      allow(I18n).to receive(:t)
        .with('hot streak', scope: %i[activerecord enums score_modifier name])
        .and_return('a translated label')

      expect(helper.score_modifier_name_label('hot streak')).to eq('a translated label')
    end
  end
end
