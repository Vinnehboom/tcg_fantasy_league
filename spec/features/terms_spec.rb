require 'rails_helper'

RSpec.describe 'Terms of Service' do
  it 'marks the page as placeholder content, not reviewed real terms' do
    visit terms_path

    expect(page).to have_content('placeholder Terms of Service')
    expect(page).to have_content('Real, reviewed terms will replace this text before launch')
  end
end
