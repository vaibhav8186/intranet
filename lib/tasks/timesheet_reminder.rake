require 'time_difference'
namespace :timesheet_reminder do
  desc "Remainds to employee to fill timesheet"
  task :ts_reminders => :environment do
    unfilled_timesheet_date = []
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
      last_filled_time_sheet_date = user.time_sheets.order(date: :asc).last.date + 1 if is_time_sheet_present?(user)
      next if last_filled_time_sheet_date.nil?
      date_difference = TimeDifference.between(DateTime.current, DateTime.parse(last_filled_time_sheet_date.to_s)).in_days.round
      if date_difference < 2
        next if HolidayList.is_holiday?(last_filled_time_sheet_date)
        unless is_user_on_leave?(user, last_filled_time_sheet_date)
          unfilled_timesheet_date << last_filled_time_sheet_date unless is_time_sheet_filled?(user, last_filled_time_sheet_date)
        end
      else
        while(last_filled_time_sheet_date < Date.today)
          next last_filled_time_sheet_date += 1 if HolidayList.is_holiday?(last_filled_time_sheet_date)
          unless is_user_on_leave?(user, last_filled_time_sheet_date)
            unfilled_timesheet_date << last_filled_time_sheet_date unless is_time_sheet_filled?(user, last_filled_time_sheet_date)
            break
          end
          last_filled_time_sheet_date += 1
        end
      end

      unless unfilled_timesheet_date.blank?
        slack_uuid = user.public_profile.slack_handle
        text = "*Fill your time sheet from #{unfilled_timesheet_date} this date*"
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
    leave_applications = user.leave_applications.where(:start_at.gte => date)
    leave_applications.each do |leave_application|
      return true if date.between?(leave_application.start_at, leave_application.end_at)
    end
    return false
  end

  def is_time_sheet_filled?(user, date)
    filled_time_sheet_dates = user.time_sheets.pluck(:date)
    return false unless filled_time_sheet_dates.include?(date)
    return true
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