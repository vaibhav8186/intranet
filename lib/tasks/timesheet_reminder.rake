require 'time_difference'
namespace :timesheet_reminder do
  desc "Remainds to employee to fill timesheet"
  task :ts_reminders => :environment do
    unfilled_timesheet_date = []
    return if HolidayList.is_holiday?(Date.today)
    @time_sheet = TimeSheet.new
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
      last_filled_time_sheet_date = user.time_sheets.order(date: :asc).last.date + 1 if time_sheet_present?(user)
      next if last_filled_time_sheet_date.nil?
      date_difference = TimeDifference.between(DateTime.current, DateTime.parse(last_filled_time_sheet_date.to_s)).in_days.round
      if date_difference < 2 && last_filled_time_sheet_date < Date.today
        next if HolidayList.is_holiday?(last_filled_time_sheet_date)
        unless @time_sheet.user_on_leave?(user, last_filled_time_sheet_date)
          unfilled_timesheet_date << last_filled_time_sheet_date unless @time_sheet.time_sheet_filled?(user, last_filled_time_sheet_date)
        end
      else
        while(last_filled_time_sheet_date < Date.today)
          next last_filled_time_sheet_date += 1 if HolidayList.is_holiday?(last_filled_time_sheet_date)
          unless @time_sheet.user_on_leave?(user, last_filled_time_sheet_date)
            unfilled_timesheet_date << last_filled_time_sheet_date unless @time_sheet.time_sheet_filled?(user, last_filled_time_sheet_date)
            break
          end
          last_filled_time_sheet_date += 1
        end
      end

      unless unfilled_timesheet_date.blank?
        slack_uuid = user.public_profile.slack_handle
        text = "*Fill your time sheet from #{unfilled_timesheet_date}*"
        send_reminder(slack_uuid, text) unless slack_uuid.blank?
        unfilled_timesheet_date = []
      end
    end  
  end

  def time_sheet_present?(user)
    unless @time_sheet.check_time_sheet(user)
      slack_uuid = user.public_profile.slack_handle
      text = "*Fill your time sheet of yesterday*"
      send_reminder(slack_uuid, text) unless slack_uuid.blank?
      return false
    end
    return true
  end

  def send_reminder(user_id, text)
    resp = JSON.parse(SlackApiService.new.open_direct_message_channel(user_id))
    SlackApiService.new.post_message_to_slack(resp['channel']['id'], text)
    SlackApiService.new.close_direct_message_channel(resp['channel']['id'])
  end

end