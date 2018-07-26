namespace :timesheet_reminder do
  desc "Remainds to employee to fill timesheet"
  task :ts_reminders => :environment do
    unfill_timesheet_date = []
    return if HolidayList.is_holiday?(Date.today)
    users = User.where(
      '$and' => [
        '$or' => [
          { role: 'Intern' },
          { role: 'Employee' }
        ],
        status: 'Approved'
      ]
    )

    users.each do |user|
      last_time_sheet_date = user.time_sheets.last.date if is_time_sheet_present?(user)
      yesterday_date = Date.yesterday
      next if last_time_sheet_date.nil?

      while(last_time_sheet_date <= yesterday_date)
        next if HolidayList.is_holiday?(yesterday_date)
        unless is_user_on_leave?(user, yesterday_date)
          fill_time_sheet_dates = user.time_sheets.pluck(:date)
          unfill_timesheet_date << yesterday_date unless fill_time_sheet_dates.include?(yesterday_date)
          break
        end
        yesterday_date -= 1
      end

      unless unfill_timesheet_date.blank?
        slack_uuid = user.public_profile.slack_handle
        text = "#{unfill_timesheet_date} *Fill your time sheet for this date*"
        send_reminder(slack_uuid, text) unless slack_uuid.blank?
      end
    end  
  end

  def is_time_sheet_present?(user)
    unless user.time_sheets.present?
      slack_uuid = user.public_profile.slack_handle
      text = "*Fill your time sheet of yesterday*"
      send_reminder(slack_uuid, text) unless slack_uuid.blank?
      return false
    end
    return true
  end

  def is_user_on_leave?(user, date)
    return false unless user.leave_applications.present?
    leave_start_at = user.leave_applications[0].start_at
    leave_end_at = user.leave_applications[0].end_at

    date.between?(leave_start_at, leave_end_at)
  end

  def send_reminder(user_id, text)
    resp = JSON.parse(open_direct_message_channel(user_id))
    slack_params = {
      token: SLACK_API_TOKEN,
      channel: resp['channel']['id'],
      text: text
    }

    RestClient.post("https://slack.com/api/chat.postMessage", slack_params)
    close_direct_message_channel(resp['channel']['id'])
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