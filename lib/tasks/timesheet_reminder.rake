require 'time_difference'
namespace :timesheet_reminder do
  desc "Remainds to employee to fill timesheet"
  task :ts_reminders => :environment do
    return if HolidayList.is_holiday?(Date.today)
    @time_sheet = TimeSheet.new
    users = User.get_approved_users_to_send_reminder
    TimeSheet.search_user_and_send_reminder(users)
  end
end