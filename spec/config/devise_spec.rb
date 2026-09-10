require 'rails_helper'

RSpec.describe 'Devise configuration' do
  it 'is paranoid, so a lookup failure never reveals whether an email is registered' do
    expect(Devise.paranoid).to be(true)
  end

  it 'times a session out after 30 minutes of inactivity' do
    expect(Devise.timeout_in).to eq(30.minutes)
  end

  it 'grants no unconfirmed access period' do
    expect(Devise.allow_unconfirmed_access_for).to eq(0.days)
  end

  it 'requires User to be confirmable and timeoutable' do
    expect(User.devise_modules).to include(:confirmable, :timeoutable)
  end
end
