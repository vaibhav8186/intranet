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

  MAX_COMMAND_LENGTH = 5
  DATE_FORMAT_LENGTH = 3
  
  def parse_string(params)
    split_text = params['text'].split

    return false unless is_valid_command_format?(split_text, params['channel_id'])
    return false unless is_valid_project_name?(split_text[0], params)
    return false unless is_valid_date_format?(split_text[1], params)
    return false unless time_validation(split_text[2], split_text[3], params)
    time_sheets_data = time_sheets(split_text, params)
    return true, time_sheets_data
  end

  def is_valid_command_format?(split_text, channel_id)
    if split_text.length < MAX_COMMAND_LENGTH
      text = "\`Error :: Invalid timesheet format\`"
      post_message_to_slack(channel_id, text)
      return false
    end
    return true
  end

  def is_valid_project_name?(project_name, params)
    user = load_user(params['user_id'])
    display_names = user.first.projects.pluck(:display_name)
    return true if display_names.include?(project_name)
    text = "\`Error :: you are not working on this project\`"
    post_message_to_slack(params['channel_id'], text)
    return false
  end

  def is_valid_date_format?(date, params)
    split_date = date.include?('/')? date.split('/') : date.split('-')
    
    if split_date.length < DATE_FORMAT_LENGTH
      text = "\`Error :: Invalid date format\`"
      post_message_to_slack(params['channel_id'], text)
      return false
    end
    
    is_valid_date(split_date, date, params)
  end
  
  def is_valid_date(split_date, date, params)
    valid_date = Date.valid_date?(split_date[2].to_i, split_date[1].to_i, split_date[0].to_i)
    unless valid_date
      post_message_to_slack(params['channel_id'], "\`Error :: Invalid date\`")
      return false
    end
    
    check_date_range(date, params)
  end
  
  def check_date_range(date, params)
    if Date.parse(date) > Date.today || Date.parse(date) < 7.days.ago
      text = "\`Error :: Date should be in last week\`"
      post_message_to_slack(params['channel_id'], text)
      return false
    end
    return true
  end
  
  def time_validation(start_time, end_time, params)
    start_time = is_valid_time?(start_time, params)
    end_time = is_valid_time?(end_time, params)
    
    return false unless start_time || end_time
    
    if start_time > end_time
      text = "\`Error :: From time must be less than to time\`"
      post_message_to_slack(params['channel_id'], text)
      return false
    end
    return true
  end
  
  def is_valid_time?(time, params)
    time_format = check_time_format(time)
    ret = Time.parse(time_format) rescue nil
    
    unless ret
      text = "\`Error :: Invalid time formate\`"
      post_message_to_slack(params['channel_id'], text)
      return false
    end
    ret
  end
  
  def check_time_format(time)
    return time + (':00') unless time.include?(':')
    time
  end
  
  def concat_desscription(split_text)
    description = ''
    split_text[4..-1].each do |string|
      description = description + ' ' + string
    end
    description
  end
  
  def time_sheets(split_text, params)
    user = load_user(params['user_id'])
    time_sheets_data = {}
    time_sheets_data['user_id'] = user.first.id
    time_sheets_data['project_id'] = user.first.projects.find_by(display_name: split_text[0]).id
    time_sheets_data['date'] = split_text[1]
    time_sheets_data['from_time'] = split_text[2]
    time_sheets_data['to_time'] = split_text[3]
    time_sheets_data['description'] = concat_desscription(split_text)
    time_sheets_data
  end
   
  def post_message_to_slack(channel, text)
    params = {
      token: SLACK_API_TOKEN,
      channel: channel,
      text: text
    }
    resp = RestClient.post("https://slack.com/api/chat.postMessage", params)
  end
  
  def load_user(user_id)
    User.where("public_profile.slack_handle" => user_id)
  end
end


