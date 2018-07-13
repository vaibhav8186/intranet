class TimeSheet
  include Mongoid::Document

  field :user_id
  field :project_id
  field :date
  field :from_time
  field :to_time
  field :description

  belongs_to :user
  belongs_to :project

  def parse_string(time_sheets_text, params)
    split_text = time_sheets_text.split

    return false unless is_valid_command_format?(split_text, params['channel_id'])
    return false unless is_valid_project_name?(split_text[0], params)
    return false unless is_valid_date_format?(split_text[1], params)
    return true
  end

  def is_valid_command_format?(split_text, channel_id)
    if split_text.length < 5
      text = "*Error :: Invalid timesheet format*"
      post_message_to_slack(channel_id, text)
      return false
    end
    return true
  end

  def is_valid_project_name?(project_name, params)
    display_names = User.where("public_profile.slack_handle" => params['user_id']).first.projects.pluck(:display_name)
    return true if display_names.include?(project_name)
    text = "*Error :: you are not working on this project*"
    post_message_to_slack(params['channel_id'], text)
    return false
  end

  def is_valid_date_format?(date, params)
    split_date = date.include?('/')? date.split('/') : date.split('-')
    
    if split_date.length < 3
      text = "*Error :: Invalid date format*"
      post_message_to_slack(params['channel_id'], text)
      return false
    end
    
    is_valid_date(split_date, date, params)
  end
  
  def is_valid_date(split_date, date, params)
    valid_date = Date.valid_date?(split_date[2].to_i, split_date[1].to_i, split_date[0].to_i)
    unless valid_date
      post_message_to_slack(params['channel_id'], "*Error :: Invalid date*")
      return false
    end
    
    check_date_range(date, params)
  end
  
  def check_date_range(date, params)
    if Date.parse(date) > Date.today || Date.parse(date) < 7.days.ago
      text = "*Error :: Date should be in last week*"
      post_message_to_slack(params['channel_id'], text)
      return false
    end
    return true
  end
  
  def post_message_to_slack(channel, text)
    params = {
      token: SLACK_API_TOKEN,
      channel: channel,
      text: text
    }
    resp = RestClient.post("https://slack.com/api/chat.postMessage", params)

    puts JSON.pretty_generate(JSON.parse(resp.body))
  end
end

