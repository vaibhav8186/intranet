desc "Give daily employee timesheet reports to admin"
task :daily_employee_timesheet => :environment do
  users = User.where(status: 'approved').to_a
  @daily_employee_timesheet = DailyEmployeeTimesheet.new
  users.each do |user|
    worked_hours = ''
    total_worked_minutes_on_projects = 0
    user.projects.includes(:time_sheets).each do |project|
      total_minutes = 0
      project.time_sheets.where(user_id: user.id, date: Date.yesterday).each do |time_sheet|
        minutes = @daily_employee_timesheet.calculate_working_minutes(time_sheet)
        total_minutes += minutes
        total_worked_minutes_on_projects += minutes
      end
      hours, minutes = @daily_employee_timesheet.calculate_hours_and_minutes(total_minutes.to_i)
      worked_hours += "#{project.display_name}: #{hours}H #{minutes}M"
    end
    free_hours, free_minute = @daily_employee_timesheet.calculate_free_hours(total_worked_minutes_on_projects)
    number_of_free_hours = "#{free_hours}.#{free_minute}".to_f
    user.daily_employee_timesheets.create(number_of_worked_hours: worked_hours,
                                          number_of_free_hours: number_of_free_hours.round(2),
                                          number_of_projects: user.projects.count)
  end
end