require 'spec_helper'

module ExternalData

  RSpec.shared_examples 'PersistableObjectInterface' do |klass|
    subject { klass.new(attributes: { external_id: 1, game_id: 1 }) }

    it { is_expected.to respond_to(:save!) }
  end

end
