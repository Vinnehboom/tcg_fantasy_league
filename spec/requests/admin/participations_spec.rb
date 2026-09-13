require 'rails_helper'

module Admin

  RSpec.describe 'Users' do
    let(:admin) { create(:user, :with_role, role: :admin) }
    let(:game) { create(:game, id: 'PTCG') }

    before do
      sign_in admin
    end

    describe '#show' do
      it 'shows the participation' do
        get admin_participation_path(create(:participation))
        expect(response).to render_template('admin/participations/show')
      end
    end

    describe '#index' do
      it 'shows all participations' do
        get admin_participations_path
        expect(response).to render_template('admin/participations/index')
      end
    end
  end

end

RSpec.describe 'A verb /admin/participations does not implement' do
  let(:participation) { create(:participation) }

  it 'redirects create to root instead of reaching any controller action' do
    post '/admin/participations'

    expect(response).to redirect_to(root_path)
  end

  it 'redirects update to root instead of reaching any controller action' do
    patch "/admin/participations/#{participation.id}"

    expect(response).to redirect_to(root_path)
  end

  it 'redirects destroy to root instead of reaching any controller action' do
    delete "/admin/participations/#{participation.id}"

    expect(response).to redirect_to(root_path)
  end
end
