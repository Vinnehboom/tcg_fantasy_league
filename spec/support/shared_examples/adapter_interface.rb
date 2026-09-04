RSpec.shared_examples 'an external data adapter' do
  it { is_expected.to respond_to(:players) }
  it { is_expected.to respond_to(:upcoming_tournaments) }
  it { is_expected.to respond_to(:results) }
  it { is_expected.to respond_to(:field_size) }
end
