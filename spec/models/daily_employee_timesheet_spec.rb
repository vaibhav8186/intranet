require 'rails_helper'

RSpec.describe DailyEmployeeTimesheet, type: :model do
  let!(:user) { FactoryGirl.create(:user) }
  let!(:daily_employee_timesheet) { FactoryGirl.create(:daily_employee_timesheet)}
  let!(:project) { user.projects.create(name: 'The pediatric network', display_name: 'The_pediatric_network') }

  context 'calculate hours and minutes' do
    it 'Should give right hours and minutes' do
      total_minutes = 359
      local_var_hours = total_minutes / 60
      local_var_minutes = total_minutes % 60
      hours, minutes = daily_employee_timesheet.calculate_hours_and_minutes(total_minutes)
      expect(hours).to eq(local_var_hours)
      expect(minutes).to eq(local_var_minutes)
    end

    it 'Should give right difference between time' do
      user.time_sheets.create(user_id: user.id, project_id: project.id, 
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"), 
                              to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')
      user_time_sheet = user.time_sheets[0]
      time_diff = TimeDifference.between(user_time_sheet.to_time, user_time_sheet.from_time).in_minutes
      minutes = daily_employee_timesheet.calculate_working_minutes(user_time_sheet)
      expect(minutes).to eq(time_diff)
    end
  end

  context 'calculate free hours' do
    it 'Should give zero hourse and minutes because of over work' do
      free_hours, free_minute = daily_employee_timesheet.calculate_free_hours(510)
      expect(free_hours).to eq(0)
      expect(free_minute).to eq(0)
    end

    it 'Should give right free hours and minutes' do
      minutes = 400
      local_var_hours = 80 / 60
      local_var_minutes = 80 % 60
      free_hours, free_minute = daily_employee_timesheet.calculate_free_hours(minutes)
      expect(local_var_hours).to eq(free_hours)
      expect(local_var_minutes).to eq(free_minute)
    end
  end
end
