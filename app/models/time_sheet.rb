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

  MAX_TIMESHEET_COMMAND_LENGTH = 5
  DATE_FORMAT_LENGTH = 3
  MAX_DAILY_STATUS_COMMAND_LENGTH = 2

  def parse_timesheet_data(params)
    split_text = params['text'].split

    return false unless valid_command_format?(split_text, params['channel_id'])
    return false unless valid_project_name?(split_text[0], params)
    return false unless valid_date_format?(split_text[1], params)
    return false unless time_validation(split_text[1], split_text[2], split_text[3], params)

    time_sheets_data = time_sheets(split_text, params)
    return true, time_sheets_data
  end

  def valid_command_format?(split_text, channel_id)
    if split_text.length < MAX_TIMESHEET_COMMAND_LENGTH
      text = "\`Error :: Invalid timesheet format. Format should be <project_name> <date> <from_time> <to_time> <description>\`"
      SlackApiService.new.post_message_to_slack(channel_id, text)
      return false
    end
    return true
  end

  def valid_project_name?(project_name, params)
    user = load_user(params['user_id'])
    project = user.first.projects.find_by(display_name: /^#{project_name}$/i) rescue nil
    return true if !project.nil? || project_name == 'other'
    text = "\`Error :: You are not working on this project. Use /projects command to view your project\`"
    SlackApiService.new.post_message_to_slack(params['channel_id'], text)
    return false
  end

  def valid_date_format?(date, params)
    split_date = date.include?('/')? date.split('/') : date.split('-')
    
    if split_date.length < DATE_FORMAT_LENGTH
      text = "\`Error :: Invalid date format. Format should be dd/mm/yyyy\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end

    valid_date?(split_date, date, params)
  end

  def valid_date?(split_date, date, params)
    valid_date = Date.valid_date?(split_date[2].to_i, split_date[1].to_i, split_date[0].to_i)
    unless valid_date
      SlackApiService.new.post_message_to_slack(params['channel_id'], "\`Error :: Invalid date\`")
      return false
    end

    return true if params['command'] == '/daily_status'
    check_date_range(date, params)
  end
  
  def check_date_range(date, params)
    if Date.parse(date) < 7.days.ago
      text = "\`Error :: Not allowed to fill timesheet for this date. If you want to fill the timesheet, meet your manager.\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    elsif Date.parse(date) > Date.today
      text = "\`Error :: Can't fill the timesheet for future date.\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end
    return true
  end

  def from_time_greater_than_to_time?(from_time, to_time, params)
    if from_time >= to_time
       text = "\`Error :: From time must be less than to time\`"
       SlackApiService.new.post_message_to_slack(params['channel_id'], text)
       return false
     end
     return true
  end

  def timesheet_greater_than_current_time?(from_time, to_time, params)
    if from_time >= Time.now || to_time >= Time.now
      text = "\`Error :: Can't fill the timesheet for future time.\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end
    return true
  end

  def time_validation(date, from_time, to_time, params)
    from_time = valid_time?(date, from_time, params)
    to_time = valid_time?(date, to_time, params)
    return false unless from_time && to_time
    return false unless from_time_greater_than_to_time?(from_time, to_time, params)
    return false unless timesheet_greater_than_current_time?(from_time, to_time, params)

    return true, from_time, to_time
  end
  
  def valid_time?(date, time, params)
    time_format = check_time_format(time)

    if time_format
      return_value = Time.parse(date + ' ' + time_format) rescue nil
    end

    unless return_value
      text = "\`Error :: Invalid time format. Format should be HH:MM\`"
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

  def parse_daily_status_command(params)
    split_text = params['text'].split
    if split_text.length < MAX_DAILY_STATUS_COMMAND_LENGTH
      time_sheet_log = get_time_sheet_log_for_today(params) unless split_text.present?
      time_sheet_log = get_time_sheet_log_for_date(params, split_text[0]) if split_text.present?
    else
      text = "\`Error :: Invalid command options. Use /daily_status <date> to view your timesheet log\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
    end
    time_sheet_log.present? ? time_sheet_log : false
  end

  def get_time_sheet_log_for_today(params)
    user = load_user(params['user_id'])
    time_sheets, time_sheet_message = load_time_sheets(user, Date.today)
    return false unless time_sheet_present?(time_sheets, params)
    time_sheets = remove_date_from_time(time_sheets, Date.today.to_s)
    time_sheet_log = prepend_index(time_sheets)
    time_sheet_message + ". Details are following\n\n" + time_sheet_log
  end

  def get_time_sheet_log_for_date(params, date)
    return false unless valid_date_format?(date, params)
    user = load_user(params['user_id'])
    time_sheets, time_sheet_message = load_time_sheets(user, Date.parse(date))
    return false unless time_sheet_present?(time_sheets, params)
    time_sheets = remove_date_from_time(time_sheets, date.to_date.to_s)
    time_sheet_log = prepend_index(time_sheets)
    time_sheet_message + ". Details are as follow\n\n" + time_sheet_log
  end

  def time_sheet_present?(time_sheets, params)
    unless time_sheets.present?
      text = "\`Error :: Record not found\`"
      SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      return false
    end
    return true
  end

  def remove_date_from_time(time_sheets, date)
    time_sheets.each do |time_sheet|
      time_sheet[1] = time_sheet[1].to_s.remove("#{date} - ")
      time_sheet[2] = time_sheet[2].to_s.remove("#{date} - ")
    end
  end

  def prepend_index(time_sheets)
    time_sheet_log = time_sheets.each_with_index.map{|time_sheet, index| time_sheet.join(' ').prepend("#{index + 1}. ") + " \n"}
    time_sheet_log.join('')
  end

  def check_time_sheet(user)
    return false unless user.time_sheets.present?
    return true
  end

  def user_on_leave?(user, date)
    return false unless user.leave_applications.present?
    leave_applications = user.leave_applications.where(:start_at.gte => date)
    leave_applications.each do |leave_application|
      return true if date.between?(leave_application.start_at, leave_application.end_at)
    end
    return false
  end

  def time_sheet_filled?(user, date)
    filled_time_sheet_dates = user.time_sheets.pluck(:date)
    return false unless filled_time_sheet_dates.include?(date)
    return true
  end

  def load_time_sheets(user, date)
    time_sheet_log = []
    total_minutes = 0
    time_sheet_message = 'You worked on'
    user.first.projects.includes(:time_sheets).each do |project|
      project.time_sheets.where(date: date).each do |time_sheet|
        time_sheet_data = []
        time_sheet_data.push(project.name, time_sheet.from_time, time_sheet.to_time, time_sheet.description)
        time_sheet_log << time_sheet_data
        minutes = calculate_working_minutes(time_sheet)
        total_minutes += minutes
        time_sheet_data = []
      end
      hours, minitues = calculate_hours_and_minutes(total_minutes.to_i)
      next if hours == 0 && minitues == 0
      time_sheet_message += " *#{project.name}: #{hours}H #{minitues}M*" 
    end
    return time_sheet_log, time_sheet_message
  end

  def calculate_hours_and_minutes(total_minutes)
    hours = total_minutes / 60
    minutes = total_minutes % 60
    return hours, minutes
  end

  def calculate_working_minutes(time_sheet)
    TimeDifference.between(time_sheet.to_time, time_sheet.from_time).in_minutes
  end

  def load_project(user, display_name)
    user.first.projects.where(display_name: /^#{display_name}$/i).first
  end

  def load_user(user_id)
    User.where("public_profile.slack_handle" => user_id)
  end

  def fetch_email_and_associate_to_user(user_id)
    call_slack_api_service_and_fetch_email(user_id)
  end

end
