## Including spec must define `perform_import`, a zero-arg proc that calls
## `subject.perform_now` with whatever keyword arguments that job needs
## (every job's own perform: signature differs — game_id: vs tournament_id:).
RSpec.shared_examples 'an external data import job' do
  it { is_expected.to respond_to(:perform) }

  it 'creates exactly one ExternalRequest row per run' do
    expect { perform_import.call }.to change(ExternalRequest, :count).by(1)
  end
end
