require 'rails_helper'

RSpec.describe SlackController do
  context 'get_projects' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project_tpn) { user.projects.create(name: 'tpn') }
    let!(:project_ds) { user.projects.create(name: 'Dealsignal') }

    before do
      user.public_profile.slack_handle = USER_ID
      user.save
    end

    it 'should have status code 200' do
      params = { user_id: USER_ID, channel_id: CHANNEL_ID }
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "1. tpn\n2. Dealsignal"
      }

      VCR.use_cassette 'success' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"),slack_params)
        resp = JSON.parse(response.body)
        expect(resp['ok']).to eq(true)
      end

      stub_request(:post, "https://slack.com/api/chat.postMessage")

      post :projects, params
      expect(response).to have_http_status(200)
    end
  end

end
