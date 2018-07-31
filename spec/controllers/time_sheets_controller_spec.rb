require 'rails_helper'

RSpec.describe TimeSheetsController, type: :controller do
  context 'create' do
    let(:user) { FactoryGirl.create(:user) }

    before do
      user.public_profile.slack_handle = USER_ID
      user.projects.create(name: 'England Hockey', display_name: 'England_Hockey')
      user.save
      stub_request(:post, "https://slack.com/api/chat.postMessage")
    end

    it 'Should success' do
      params = {
        'user_id' => USER_ID, 
        'channel_id' => CHANNEL_ID, 
        'text' => "England_Hockey #{Date.yesterday}  6 7 abcd efghigk lmnop"
      }

      post :create, params
      resp = JSON.parse(response.body)
      expect(response).to have_http_status(:created)
      expect(resp['text']).to eq("*Timesheet save successfully*")
    end

    it 'should fail because validation trigger on timesheet data' do
      params = {
        'user_id' => USER_ID, 
        'channel_id' => CHANNEL_ID, 
        'text' => 'England 14-07-2018  6 7 abcd efghigk lmnop' 
      }

      post :create, params
      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'Check user is exists' do
    let(:user) { FactoryGirl.create(:user, email: 'ajay@joshsoftware.com') }
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
      post :create, params
      expect(response).to have_http_status(:created)
    end
  end

end
