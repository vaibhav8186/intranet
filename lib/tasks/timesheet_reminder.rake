namespace :timesheet_reminder do
  desc "Remainds to employee to fill timesheet"
  task :ts_reminders => :environment do
    unfill_timesheet_dates = []
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
      fill_time_sheet_date = user.time_sheets.order(date: :asc).last.date + 1 if is_time_sheet_present?(user)
      next if fill_time_sheet_date.nil?
      while(fill_time_sheet_date < Date.today)
        next if HolidayList.is_holiday?(fill_time_sheet_date) 
        unless is_user_on_leave?(user, fill_time_sheet_date)
          unfill_timesheet_dates << fill_time_sheet_date
        end
        fill_time_sheet_date += 1
      end
      
      unless unfill_timesheet_dates.blank?
        slack_uuid = user.public_profile.slack_handle
        text = "#{unfill_timesheet_dates} *Fill your time sheet for this date*"
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
  
  def send_reminder(channel_id, text)
    slack_params = {
      token: SLACK_API_TOKEN,
      channel: channel_id,
      text: text
    }
    
    RestClient.post("https://slack.com/api/chat.postMessage", slack_params)
  end
end