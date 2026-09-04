require 'rails_helper'

RSpec.describe 'config/environments/development.rb' do
  subject(:source) { Rails.root.join('config/environments/development.rb').read }

  it 'eager loads code on boot, so STI subclasses like ScoreModifier.subclasses ' \
     'are populated on the first request, not only once something else has loaded them' do
    expect(source).to match(/^\s*config\.eager_load = true\s*$/)
  end
end
