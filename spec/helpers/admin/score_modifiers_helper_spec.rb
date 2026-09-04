require 'rails_helper'

RSpec.describe Admin::ScoreModifiersHelper do
  describe '#score_modifier_name_label' do
    subject { helper.score_modifier_name_label('hot streak') }

    it { is_expected.to eq('hot streak') }
  end
end
