require 'rails_helper'

RSpec.describe 'DataSubjectRequests' do
  describe '#create' do
    it 'ignores a client-submitted request_type and always records erase_or_object' do
      player = create(:player)

      post data_subject_requests_path, params: {
        data_subject_request: { player_id: player.id, contact_email: 'ash@example.com', request_type: 'bogus_type' }
      }

      expect(DataSubjectRequest.sole).to be_erase_or_object
    end
  end
end
