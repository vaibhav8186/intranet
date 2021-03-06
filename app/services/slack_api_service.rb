class SlackApiService
  def post_message_to_slack(channel, text)
    params = {
      token: SLACK_API_TOKEN,
      channel: channel,
      text: text
    }
    response = RestClient.post("https://slack.com/api/chat.postMessage", params)    
  end

  def get_user_info(user_id)
    params = {
      token: SLACK_API_TOKEN,
      user: user_id
    }

    response = RestClient.post("https://slack.com/api/users.info", params)
    return false if JSON.parse(response)['ok'] == false
    JSON.parse(response)['user']['profile']['email']
  end

  def open_direct_message_channel(user_id)
    params = {
      token: SLACK_API_TOKEN,
      user: user_id
    }

    RestClient.post("https://slack.com/api/im.open", params)
  end

  def close_direct_message_channel(channel_id)
    params = {
      token: SLACK_API_TOKEN,
      channel: channel_id
    }

    RestClient.post("https://slack.com/api/im.close", params)
  end
end