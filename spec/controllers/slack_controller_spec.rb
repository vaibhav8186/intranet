require 'rails_helper'

RSpec.describe SlackController do
  context 'projects' do
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
      post :projects, params

      resp = JSON.parse(response.body)
      expect(response).to have_http_status(200)
      expect(resp['text']).to eq("1. tpn\n2. Dealsignal")
    end

    it 'Should give message : You are not working on any project' do
      user.projects.destroy_all
      params = { user_id: USER_ID, channel_id: CHANNEL_ID }

      post :projects, params
      resp = JSON.parse(response.body)
      expect(resp['text']).to eq('You are not working on any project')
    end
  end

  context 'Check user is exists' do
    let!(:user) { FactoryGirl.create(:user, email: 'ajay@joshsoftware.com') }

    before do
      user.projects.create(name: 'England Hockey', display_name: 'England_Hockey')
      user.save
      stub_request(:post, "https://slack.com/api/chat.postMessage")
    end

    it 'Associate slack id to user' do
      params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'user_id' => USER_ID,
        'text' => "England_Hockey #{Date.yesterday}  6 7 abcd efghigk lmnop"
      }

      post :projects, params
      expect(response).to have_http_status(:ok)
    end
  end

end
