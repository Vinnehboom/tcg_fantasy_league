require 'rails_helper'

RSpec.describe Demo::ProductionGuard do
  let(:includer_class) do
    Class.new do
      include Demo::ProductionGuard

      def self.name
        'ProductionGuardTestIncluder'
      end
    end
  end

  describe '#raise_outside_the_sandbox!' do
    context 'when Rails.env is production' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production')) }

      it 'raises a plain RuntimeError naming the includer, not an ExternalData::Exception' do
        expect { includer_class.new.raise_outside_the_sandbox! }
          .to raise_error(RuntimeError, /ProductionGuardTestIncluder must never run/)
      end
    end

    context 'when Rails.env is not production' do
      it 'does not raise' do
        expect { includer_class.new.raise_outside_the_sandbox! }.not_to raise_error
      end
    end
  end
end
