require 'rails_helper'

RSpec.describe SlackBot, type: :model do
  context 'Slack bot' do
    it 'it should prepend index to projects array' do
      projects = ['tpn', 'Dealsignal']
      return_value = SlackBot.new.prepend_index(projects)
      expect(return_value).to eq("1. tpn\n2. Dealsignal")
    end

    it 'Should return true because user id is valid' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'user' => USER_ID
      }
      VCR.use_cassette 'success_user_info' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/users.info"), slack_params)
        resp = JSON.parse(response.body)
        expect(resp['ok']).to eq(true)
      end
    end

    it 'Should return false because user id is invalid' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'user' => 'ABCD8F'
      }
      VCR.use_cassette 'failure_user_info' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/users.info"), slack_params)
        resp = JSON.parse(response.body)
        expect(resp['ok']).to eq(false)
        expect(resp['error']).to eq('user_not_found')
      end
    end
  end
end
