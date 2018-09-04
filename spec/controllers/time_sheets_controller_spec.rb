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
      expect(resp['text']).to eq("*Timesheet saved successfully!*")
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

  context 'Timesheet: Daily status' do
    let(:user) { FactoryGirl.create(:user, email: 'ajay@joshsoftware.com') }
    let!(:tpn) { user.projects.create(name: 'The pediatric network', display_name: 'The_pediatric_network') }

    context 'command with date option' do
      before do
        stub_request(:post, "https://slack.com/api/chat.postMessage")
        user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                                date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                                to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')
      end

      it 'Should success : user worked on single project' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => Date.yesterday.to_s
        }

        post :daily_status, params
        resp = JSON.parse(response.body)
        expect(resp['text']).to eq("You worked on *The pediatric network: 1H 0M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n")
        expect(response).to have_http_status(:ok)
      end

      it 'Should success : user worked on multiple projects' do
        deal_signal = user.projects.create(name: 'Deal signal', display_name: 'deal_signal')
        user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                                date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                                to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')

        user.time_sheets.create(user_id: user.id, project_id: deal_signal.id,
                                date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 11:00"),
                                to_time: Time.parse("#{Date.yesterday} 12:00"), description: 'Today I finish the work')
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => Date.yesterday.to_s
        }
        post :daily_status, params
        resp = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(resp['text']).to eq("You worked on *The pediatric network: 1H 0M* *Deal signal: 1H 0M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n2. Deal signal 11:00AM 12:00PM Today I finish the work \n")
      end

      it 'Should fail because invalid date' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => '06/13/2018'
        }

        post :daily_status, params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'command without date option' do
      before do
        stub_request(:post, "https://slack.com/api/chat.postMessage")
      end

      it 'Should success : user worked single project' do
        user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                                date: Date.today, from_time: '9:00',
                                to_time: '10:00', description: 'Today I finish the work')
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => ""
        }

        post :daily_status, params
        resp = JSON.parse(response.body)
        expect(resp['text']).to eq("You worked on *The pediatric network: 1H 0M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n")
        expect(response).to have_http_status(:ok)
      end

      it 'Should success : user worked on multiple project' do
        deal_signal = user.projects.create(name: 'Deal signal', display_name: 'deal_signal')
        user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                                date: Date.today, from_time: '9:00',
                                to_time: '10:00', description: 'Today I finish the work')

        user.time_sheets.create(user_id: user.id, project_id: deal_signal.id,
                                date: Date.today, from_time: '11:00',
                                to_time: '12:00', description: 'Today I finish the work')
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => ""
        }
        post :daily_status, params
        resp = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(resp['text']).to eq("You worked on *The pediatric network: 1H 0M* *Deal signal: 1H 0M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n2. Deal signal 11:00AM 12:00PM Today I finish the work \n")
      end

      it 'Should fail because timesheet not present' do
        user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                                date: Date.today - 1, from_time: '9:00',
                                to_time: '10:00', description: 'Today I finish the work')
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => ""
        }

        post :daily_status, params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context 'index' do
    let(:user) { FactoryGirl.create(:user, email: 'ajay@joshsoftware.com') }
    let!(:tpn) { user.projects.create(name: 'The pediatric network', display_name: 'The_pediatric_network') }

    it 'Should success' do
      deal_signal = user.projects.create(name: 'Deal signal', display_name: 'deal_signal')
      user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                              to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')

      user.time_sheets.create(user_id: user.id, project_id: deal_signal.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 11:00"),
                              to_time: Time.parse("#{Date.yesterday} 12:00"), description: 'Today I finish the work')
      params = {from_date: Date.yesterday - 1, to_time: Date.today}
      get :index, params
      expect(response).to have_http_status(200)
      should render_template(:index)
    end
  end

  context 'Show' do
    let!(:user) { FactoryGirl.create(:user, email: 'abc@joshsoftware.com', role: 'Admin') }
    let!(:tpn) { user.projects.create(name: 'The pediatric network', display_name: 'The_pediatric_network') }

    it 'Should success' do
      deal_signal = user.projects.create!(name: 'Deal signal', display_name: 'deal_signal')
      user.time_sheets.create!(user_id: user.id, project_id: tpn.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                              to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')

      user.time_sheets.create!(user_id: user.id, project_id: deal_signal.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 11:00"),
                              to_time: Time.parse("#{Date.yesterday} 12:00"), description: 'Today I finish the work')
      params = {user_id: user.id, from_date: Date.yesterday - 1, to_time: Date.today}
      get :show, id: user.id, user_id: user.reload.id, from_date: Date.yesterday - 1, to_time: Date.today
      expect(response).to have_http_status(200)
      should render_template(:show)
    end
  end
end
