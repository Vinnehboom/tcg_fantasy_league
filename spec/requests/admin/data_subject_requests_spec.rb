require 'rails_helper'

module Admin

  RSpec.describe 'DataSubjectRequests' do
    let(:admin) { create(:user, :with_role, role: :admin) }

    before { sign_in admin }

    describe '#index' do
      it 'renders the index template' do
        get admin_data_subject_requests_path

        expect(response).to render_template('admin/data_subject_requests/index')
      end

      it 'lists a request by its player, type and status' do
        player = create(:player, name: 'Ash Ketchum')
        create(:data_subject_request, player:)

        get admin_data_subject_requests_path

        expect(response.body).to include('Ash Ketchum')
        expect(response.body).to include(I18n.t('activerecord.enums.data_subject_request.request_type.erase_or_object'))
        expect(response.body).to include(I18n.t('activerecord.enums.data_subject_request.status.queued'))
      end

      it 'shows the suppressed placeholder, never the real name, once the request has been actioned' do
        player = create(:player, name: 'Ash Ketchum')
        create(:data_subject_request, :actioned, player:)
        player.update!(suppressed_at: Time.current)

        get admin_data_subject_requests_path

        expect(response.body).to include(I18n.t('players.suppressed_display_name'))
        expect(response.body).not_to include('Ash Ketchum')
      end

      context 'when there are no requests at all' do
        it 'renders an empty state' do
          get admin_data_subject_requests_path

          expect(response.body).to include(I18n.t('admin.data_subject_requests.index.no_requests'))
        end
      end
    end

    describe '#show' do
      it 'renders the show template' do
        get admin_data_subject_request_path(create(:data_subject_request))

        expect(response).to render_template('admin/data_subject_requests/show')
      end
    end

    context 'when the visitor is not an admin' do
      it 'refuses the list' do
        sign_in create(:user)

        get admin_data_subject_requests_path

        expect(response).to redirect_to(root_path)
      end

      it 'refuses the show page' do
        sign_in create(:user)

        get admin_data_subject_request_path(create(:data_subject_request))

        expect(response).to redirect_to(root_path)
      end
    end
  end

end
