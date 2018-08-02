class TimeSheet
  include Mongoid::Document
  include Mongoid::Timestamps
  include CheckUser

  field :user_id
  field :project_id
  field :date,            :type => Date
  field :from_time,       :type => Time
  field :to_time,         :type => Time
  field :description,     :type => String

  belongs_to :user
  belongs_to :project

  validates :from_time, :to_time, uniqueness: { scope: [:user_id, :date], message: "record is already present" }

  MAX_COMMAND_LENGTH = 5
  DATE_FORMAT_LENGTH = 3

  def parse_timesheet_data(params)
    split_text = params['text'].split

    return false unless is_valid_command_format?(split_text, params['channel_id'])
    return false unless is_valid_project_name?(split_text[0], params)
    return false unless is_valid_date_format?(split_text[1], params)
    return false unless time_validation(split_text[1], split_text[2], split_text[3], params)

    time_sheets_data = time_sheets(split_text, params)
    return true, time_sheets_data
  end

  def is_valid_command_format?(split_text, channel_id)
    if split_text.length < MAX_COMMAND_LENGTH
      text = "\`Error :: Invalid timesheet format. Format should be <project_name> <date> <from_time> <to_time> <description>\`"
      SlackApiService.new.post_message_to_slack(channel_id, text)
      return false
    end
    return true
  end

  def is_valid_project_name?(project_name, params)
    user = load_user(params['user_id'])
    project = user.first.projects.find_by(display_name: /^#{project_name}$/i) rescue nil
    return true if !project.nil? || project_name == 'other'
    text = "\`Error :: you are not working on this project. Use /projects command to view your project\`"
    SlackApiService.new.post_message_to_slack(params['channel_id'], text)
    return false
  end

  def is_valid_date_format?(date, params)
    split_date = date.include?('/')? date.split('/') : date.split('-')
    
    if split_date.length < DATE_FORMAT_LENGTH
      text = "\`Error :: Invalid date format. Format should be dd/mm/yyyy\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end

    is_valid_date(split_date, date, params)
  end

  def is_valid_date(split_date, date, params)
    valid_date = Date.valid_date?(split_date[2].to_i, split_date[1].to_i, split_date[0].to_i)
    unless valid_date
      SlackApiService.new.post_message_to_slack(params['channel_id'], "\`Error :: Invalid date\`")
      return false
    end

    check_date_range(date, params)
  end
  
  def check_date_range(date, params)
    if Date.parse(date) > Date.today || Date.parse(date) < 7.days.ago
      text = "\`Error :: not allowed to fill timesheet for this date. If you want to fill, meet your manager.\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end
    return true
  end

  def is_from_time_greater_than_to_time?(from_time, to_time, params)
    if from_time >= to_time
      text = "\`Error :: From time must be less than to time\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end
  end

  def is_from_time_greater_than_to_time?(from_time, to_time, params)
    if from_time >= to_time
       text = "\`Error :: From time must be less than to time\`"
       SlackApiService.new.post_message_to_slack(params['channel_id'], text)
       return false
     end
     return true
  end

  def is_timesheet_greater_then_current_time?(from_time, to_time, params)
    if from_time >= Time.now || to_time >= Time.now
      text = "\`Error :: Future time is not allowed\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end
    return true
  end

  def time_validation(date, from_time, to_time, params)
    from_time = is_valid_time?(date, from_time, params)
    to_time = is_valid_time?(date, to_time, params)
    return false unless from_time && to_time
    return false unless is_from_time_greater_than_to_time?(from_time, to_time, params)
    return false unless is_timesheet_greater_then_current_time?(from_time, to_time, params)

    return true, from_time, to_time
  end
  
  def is_valid_time?(date, time, params)
    time_format = check_time_format(time)

    if time_format
      return_value = Time.parse(date + ' ' + time_format) rescue nil
    end

    unless return_value
      text = "\`Error :: Invalid time format. Format should be HH:MM:SS\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end
    return_value
  end
  
  def check_time_format(time)
    return false if time.include?('.')
    return time + (':00') unless time.include?(':')
    time
  end

  def concat_desscription(split_text)
    description = ''
    split_text[4..-1].each do |string|
      description = description + string + ' '
    end
    description
  end

  def time_sheets(split_text, params)
    time_sheets_data = {}
    user = load_user(params['user_id'])
    project = load_project(user, split_text[0])
    time_sheets_data['user_id'] = user.first.id
    time_sheets_data['project_id'] = project.nil? ? nil : project.id
    time_sheets_data['date'] = Date.parse(split_text[1])
    time_sheets_data['from_time'] = Time.parse(split_text[1] + ' ' + split_text[2])
    time_sheets_data['to_time'] = Time.parse(split_text[1] + ' ' + split_text[3])
    time_sheets_data['description'] = concat_desscription(split_text)
    time_sheets_data
  end

  def load_project(user, display_name)
    user.first.projects.where(display_name: /^#{display_name}$/i).first
  end

  def load_user(user_id)
    User.where("public_profile.slack_handle" => user_id)
  end

  def check_user_is_present(user, user_id)
    is_user_present?(user, user_id)
  end

end
