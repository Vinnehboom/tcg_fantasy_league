RSpec.shared_examples 'a Scoring::Strategy' do
  it { expect(described_class).to respond_to(:for) }
  it { is_expected.to respond_to(:points_for) }
  it { is_expected.to respond_to(:using_default_config?) }
end
