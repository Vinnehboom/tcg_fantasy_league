RSpec.shared_examples 'an external data import job' do
  it { is_expected.to respond_to(:perform) }

  it 'creates exactly one ExternalRequest row per run' do
    expect { subject.perform_now }.to change(ExternalRequest, :count).by(1)
  end
end
