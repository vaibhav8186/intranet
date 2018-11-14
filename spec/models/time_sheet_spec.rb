require 'rails_helper'

RSpec.describe TimeSheet, type: :model do
  context 'Validation' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project) }
    let!(:time_sheet) { FactoryGirl.build(:time_sheet) }

    before do
      user.public_profile.slack_handle = USER_ID
      UserProject.create(user_id: user.id, project_id: project.id, start_date: DateTime.now - 2, end_date: nil)
      user.save
      stub_request(:post, "https://slack.com/api/chat.postMessage")
    end

    it 'Should success' do
      params = {
        'user_id' => USER_ID, 
        'channel_id' => CHANNEL_ID, 
        'text' => "The_pediatric_network #{Date.yesterday}  6 7 abcd efghigk lmnop"
      }

      ret = time_sheet.parse_timesheet_data(params)
      expect(ret[0]).to eq(true)
    end

    it 'Should success even if project name is lower case' do
      params = {
        'user_id' => USER_ID,
        'channel_id' => CHANNEL_ID,
        'text' => "the_pediatric_network #{Date.yesterday}  6 7 abcd efghigk lmnop"
      }

      ret = time_sheet.parse_timesheet_data(params)
      expect(ret[0]).to eq(true)
    end

    it 'Should fails because record is already present' do
      FactoryGirl.create(:time_sheet, user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: "#{Date.today - 1} 10:00", to_time: "#{Date.today - 1} 11:00", description: 'call')
      time_sheet = FactoryGirl.build(:time_sheet, user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: "#{Date.today - 1} 10:00", to_time: "#{Date.today - 1} 11:00", description: 'call')
      time_sheet.save
      expect(time_sheet.errors.full_messages).to eq(["From time `Error :: Record already present`", "To time `Error :: Record already present`"])
    end

    it 'Should return false because invalid timesheet command format' do
      params = {
        'user_id' => USER_ID, 
        'channel_id' => CHANNEL_ID, 
        'text' => 'England_Hockey 22-07-2018  6'
      }

      expect(time_sheet.parse_timesheet_data(params)).to eq(false)
    end

    it 'Should return false because user does not assign to this project' do
      params = {
        'user_id' => USER_ID, 
        'channel_id' => CHANNEL_ID,
        'text' => 'England 14-07-2018  6 7 abcd efgh'
      }
      expect(time_sheet.parse_timesheet_data(params)).to eq(false)
    end

    context 'Validation - date' do
      it 'Should return false because invalid date format' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => 'England_Hockey 14-2018  6 7 abcd efgh'
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end

      it 'Should return false because date is greater than assigned project date' do
        time_sheet = FactoryGirl.build(:time_sheet, user_id: user.id, project_id: project.id, date: DateTime.now - 3)
        expect(time_sheet.save).to eq(false)
        expect(time_sheet.errors[:date]).to eq(["Error :: Not allowed to fill timesheet for this date. As you were not assigned on project for this date"])
      end

      it 'Should return false because date is not within this week' do
        time_sheet = FactoryGirl.build(:time_sheet, user_id: user.id, project_id: project.id, date: DateTime.now - 10)
        expect(time_sheet.save).to eq(false)
        expect(time_sheet.errors[:date]).to eq(["Error :: Not allowed to fill timesheet for this date. If you want to fill the timesheet, meet your manager."])
      end

      it 'Should return false because date is invalid' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => 'The_pediatric_network 1/32/2018  6 7 abcd efgh'
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end

      it 'Should return false because date and time is greater than current date and time' do
        time_sheet = FactoryGirl.build(:time_sheet, user_id: user.id, project_id: project.id, date: DateTime.now - 1, from_time: '20:00', to_time: '20:30')
        expect(time_sheet.save).to eq(false)
        expect(time_sheet.errors[:from_time]).to eq(["Error :: Can't fill the timesheet for future time."])
      end
    end

    context 'Validation - Time' do
      it 'Should return false because invalid from time format' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => "The_pediatric_network #{Date.yesterday} 15.30 16 abcd efgh"
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end

      it 'Should return false because invalid to time format' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => "The_pediatric_network #{Date.yesterday} 6 7.00 abcd efgh"
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end

      it 'Should return false because from time is greater than to time' do
        time_sheet = FactoryGirl.build(:time_sheet, user_id: user.id, project_id: project.id, date: DateTime.now - 1, from_time: '08:00', to_time: '07:00')
        expect(time_sheet.save).to eq(false)
        expect(time_sheet.errors[:from_time]).to eq(["`Error :: From time must be less than to time`"])
      end
    end
  end

  context 'Timesheet reminder' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:time_sheet) { FactoryGirl.build(:time_sheet) }

    before do
      user.public_profile.slack_handle = USER_ID
      user.save
      stub_request(:post, "https://slack.com/api/chat.postMessage")
    end

    context 'success' do
      it 'Should give the message to fill timesheet' do
        project = FactoryGirl.create(:project)
        UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 2, end_date: nil)
        user.time_sheets.create(project_id: project.id, date: 2.days.ago, from_time: '9:00', to_time: '10:00', description: 'call')
        expect(HolidayList.is_holiday?(user.time_sheets[0].date + 1)).to eq(false)
        expect(TimeSheet.time_sheet_present_for_reminder?(user)).to eq(true)
        expect(TimeSheet.user_on_leave?(user, user.time_sheets[0].date + 1)).to eq(false)
        expect(TimeSheet.time_sheet_filled?(user, user.time_sheets[0].date + 1)).to eq(false)
        expect(TimeSheet.unfilled_timesheet_present?(user, user.time_sheets[0].date + 1)).to eq(true)
      end
    end

    context 'timesheet filled' do
      let!(:project) { FactoryGirl.create(:project) }
      before do
        UserProject.create(user_id: user.id, project_id: project.id, start_date: DateTime.now - 5, end_date: nil)
        user.time_sheets.create(project_id: project.id, date: Date.today - 1, from_time: '9:00', to_time: '10:00', description: 'Today I finish the work')
        user.time_sheets.create(project_id: project.id, date: Date.today - 2, from_time: '9:00', to_time: '10:00', description: 'Today I finish the work')
        user.time_sheets.create(project_id: project.id, date: Date.today - 3, from_time: '9:00', to_time: '10:00', description: 'Today I finish the work')
      end

      it 'Should return false because timesheet is not filled' do
        expect(TimeSheet.time_sheet_filled?(user, 4.days.ago.utc)).to eq(false)
      end

      it 'Should return true because timesheet is filled' do
        expect(TimeSheet.time_sheet_filled?(user, Date.today - 1)).to eq(true)
      end
    end

    context 'user on leave' do
      it 'Should return false because leave application is not present' do
        expect(TimeSheet.user_on_leave?(user, Date.today - 2)).to eq(false)
      end

      it 'Should return true because user is on leave' do
        FactoryGirl.create(:leave_application, user_id: user.id, leave_status: LEAVE_STATUS[1])
        expect(TimeSheet.user_on_leave?(user, Date.today + 2)).to eq(true)
      end

      it 'Should return false because user is not on leave' do
        FactoryGirl.create(:leave_application, user_id: user.id, leave_status: LEAVE_STATUS[1])
        expect(TimeSheet.user_on_leave?(user, Date.today + 4)).to eq(false)
      end
    end
  end

  context 'Daily timesheet status' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project, name: 'The pediatric network', display_name: 'The_pediatric_network') }
    let!(:time_sheet) { FactoryGirl.build(:time_sheet) }

    before do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: DateTime.now - 2, end_date: nil)
      user.public_profile.slack_handle = USER_ID
      user.save
      stub_request(:post, "https://slack.com/api/chat.postMessage")
    end

    context 'command without option' do
      it 'Should give timesheet log' do
        user.time_sheets.create(user_id: user.id, project_id: project.id, 
                                date: Date.today, from_time: '9:00', 
                                to_time: '10:00', description: 'Today I finish the work')
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => ""
        }

        time_sheets = TimeSheet.parse_daily_status_command(params)
        expect(time_sheets).to eq("You worked on *The pediatric network: 1H 00M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n")
      end

      it 'Should return false because timesheet record not present' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => ""
        }

        time_sheets = TimeSheet.parse_daily_status_command(params)
        expect(time_sheets).to eq(false)
      end
    end

    context 'command with options' do
      it 'Should give timesheet log' do
        user.time_sheets.create(user_id: user.id, project_id: project.id, 
                                date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"), 
                                to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => Date.yesterday.to_s,
          'command' => '/daily_status'
        }
        time_sheets = TimeSheet.parse_daily_status_command(params)
        expect(time_sheets).to eq("You worked on *The pediatric network: 1H 00M*. Details are as follow\n\n1. The pediatric network 09:00AM 10:00AM Today I finish the work \n")
      end

      it 'Should return false because timesheet record not present' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => Date.yesterday.to_s,
          'command' => '/daily_status'
        }
        time_sheets = TimeSheet.parse_daily_status_command(params)
        expect(time_sheets).to eq(false)
      end

      it 'Should return false because invalid date format' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => '06/07'
        }

        time_sheets = TimeSheet.parse_daily_status_command(params)
        expect(time_sheets).to eq(false)
      end

      it 'Should return false because invalid date' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => '06/13/2018'
        }

        time_sheets = TimeSheet.parse_daily_status_command(params)
        expect(time_sheets).to eq(false)
      end
    end

    it 'Should give right hours and minutes' do
      total_minutes = 359
      local_var_hours = total_minutes / 60
      local_var_minutes = total_minutes % 60
      hours, minutes = TimeSheet.calculate_hours_and_minutes(total_minutes)
      expect(hours).to eq(local_var_hours)
      expect(minutes).to eq("#{local_var_minutes}")
    end

    it 'Should give right difference between time' do
      user.time_sheets.create(user_id: user.id, project_id: project.id, 
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"), 
                              to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')
      user_time_sheet = user.time_sheets[0]
      time_diff = TimeDifference.between(user_time_sheet.to_time, user_time_sheet.from_time).in_minutes
      minutes = TimeSheet.calculate_working_minutes(user_time_sheet)
      expect(minutes).to eq(time_diff)
    end
  end

  context 'Employee timesheet report' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:time_sheet) { FactoryGirl.build(:time_sheet) }
    let!(:project) { FactoryGirl.create(:project) }
    before do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: DateTime.now - 2, end_date: nil)
    end 

    it 'Should give the project name' do
      expect(TimeSheet.get_project_name(project.id)).to eq(project.name)
    end

    it 'Should give the correct hours and minutes' do
      milliseconds = 7200000
      local_var_hours = milliseconds / (1000 * 60 * 60)
      local_var_minutes = milliseconds / (1000 * 60) % 60
      local_var_hours = local_var_minutes < 30 ? local_var_hours : local_var_hours + 1
      expect(TimeSheet.convert_milliseconds_to_hours(milliseconds)).to eq(local_var_hours) 
    end

    it 'Should give the user leaves count' do
      FactoryGirl.create(:leave_application, user_id: user.id, leave_status: LEAVE_STATUS[1])
      expect(TimeSheet.approved_leaves_count(user, Date.today + 2, Date.today + 3)).to eq(2)
    end

    it 'Should return true because from date is less than to date' do
      from_date = Date.today - 2
      to_date = Date.today
      expect(TimeSheet.from_date_less_than_to_date?(from_date, to_date)).to eq(true)
    end

    it 'Should return true because from date is equal to to date' do
      from_date = Date.today
      to_date = Date.today
      expect(TimeSheet.from_date_less_than_to_date?(from_date, to_date)).to eq(true)
    end

    it 'Should return false because from date is greater than to date' do
      from_date = Date.today + 2
      to_date = Date.today
      expect(TimeSheet.from_date_less_than_to_date?(from_date, to_date)).to eq(false)
    end

    it 'Should give the expected JSON' do
      user.time_sheets.create(user_id: user.id, project_id: project.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                              to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')
      params = {from_date: Date.yesterday - 1, to_date: Date.today}
      timesheet_record = TimeSheet.load_timesheet(user.time_sheets.pluck(:id), Date.yesterday - 1, Date.today)
      timesheet_data = TimeSheet.generete_employee_timesheet_report(timesheet_record, Date.yesterday - 1, Date.today)
      expect(timesheet_data[0]['user_name']).to eq('fname lname')
      expect(timesheet_data[0]['project_details'][0]['project_name']).to eq('The pediatric network')
      expect(timesheet_data[0]['project_details'][0]['worked_hours']).to eq('0 Days 1H (1H)')
      expect(timesheet_data[0]['total_worked_hours']).to eq('0 Days 1H (1H)')
      expect(timesheet_data[0]['leaves']).to eq(0)
    end
  end

  context 'Individual timesheet report' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:time_sheet) { FactoryGirl.build(:time_sheet) }
    let!(:tpn) { FactoryGirl.create(:project, name: 'The pediatric network', display_name: 'The_pediatric_network') }
    let!(:intranet) { FactoryGirl.create(:project, name: 'Intranet', display_name: 'Intranet') }

    it 'Should give expected JSON' do
      UserProject.create(user_id: user.id, project_id: tpn.id, start_date: DateTime.now - 3, end_date: nil)
      UserProject.create(user_id: user.id, project_id: intranet.id, start_date: DateTime.now - 3, end_date: nil)
      user.time_sheets.create(user_id: user.id, project_id: tpn.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"),
                              to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')

      user.time_sheets.create(user_id: user.id, project_id: intranet.id,
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 11:00"),
                              to_time: Time.parse("#{Date.yesterday} 13:30"), description: 'Today I finish the work')
      params = { from_date: Date.yesterday - 1, to_date: Date.today }
      individual_time_sheet_data, total_work_and_leaves = TimeSheet.generate_individual_timesheet_report(user, params)
      expect(individual_time_sheet_data.count).to eq(2)
      expect(individual_time_sheet_data['The pediatric network']['total_worked_hours']).to eq('0 Days 1H (1H)')
      expect(individual_time_sheet_data['The pediatric network']['daily_status'][0][0].to_s).to eq(DateTime.yesterday.to_s)
      expect(individual_time_sheet_data['The pediatric network']['daily_status'][0][1]).to eq('09:00AM')
      expect(individual_time_sheet_data['The pediatric network']['daily_status'][0][2]).to eq('10:00AM')
      expect(individual_time_sheet_data['The pediatric network']['daily_status'][0][3]).to eq('1:00')
      expect(individual_time_sheet_data['The pediatric network']['daily_status'][0][4]).to eq('Today I finish the work')
      expect(individual_time_sheet_data['Intranet']['total_worked_hours']).to eq('0 Days 3H (3H)')
      expect(total_work_and_leaves['total_work']).to eq('0 Days 4H (4H)')
      expect(total_work_and_leaves['leaves']).to eq(0)
    end
  end


  context 'Get allocated hours' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project, name: 'test') }

    context 'Should calculate the allcated hours between from date and to date' do
      it 'These no any holiday' do
        UserProject.create(user_id: user.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
        TimeSheet.create(user_id: user.id, project_id: project.id, date: '12/09/2018'.to_date, from_time: '9:00', to_time: '10:00', description: 'Discuss new story')
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(project, from_date, to_date)
        expect(allocated_hours).to eq("13 Days (104H)")
      end

      it 'These is one haliday' do
        UserProject.create(user_id: user.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
        TimeSheet.create(user_id: user.id, project_id: project.id, date: '12/09/2018'.to_date, from_time: '9:00', to_time: '10:00', description: 'Discuss new story')
        HolidayList.create(holiday_date: '13/09/2018'.to_date, reason: 'test')
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(project, from_date, to_date)
        expect(allocated_hours).to eq("12 Days (96H)")
      end
    end

    context "Should calculate allocated hours from user's project start date and end date" do
      it 'These no any holiday' do
        UserProject.create(user_id: user.id, project_id: project.id, start_date: '05/09/2018'.to_date, end_date: '15/09/2018'.to_date)
        TimeSheet.create(user_id: user.id, project_id: project.id, date: '12/09/2018'.to_date, from_time: '9:00', to_time: '10:00', description: 'Discuss new story')
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(project, from_date, to_date)
        expect(allocated_hours).to eq("8 Days (64H)")
      end

      it 'These is one holiday' do
        UserProject.create(user_id: user.id, project_id: project.id, start_date: '05/09/2018'.to_date, end_date: '15/09/2018'.to_date)
        TimeSheet.create(user_id: user.id, project_id: project.id, date: '12/09/2018'.to_date, from_time: '9:00', to_time: '10:00', description: 'Discuss new story')
        HolidayList.create(holiday_date: '13/09/2018'.to_date, reason: 'test')
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(project, from_date, to_date)
        expect(allocated_hours).to eq("7 Days (56H)")
      end
    end

    context "Should calculate allocated hours from user's project start date and searching to date" do
      it 'These no any holiday' do
        UserProject.create(user_id: user.id, project_id: project.id, start_date: '06/09/2018'.to_date, end_date: nil)
        TimeSheet.create(user_id: user.id, project_id: project.id, date: '12/09/2018'.to_date, from_time: '9:00', to_time: '10:00', description: 'Discuss new story')
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(project, from_date, to_date)
        expect(allocated_hours).to eq("10 Days (80H)")
      end

      it 'These is one holiday' do
        UserProject.create(user_id: user.id, project_id: project.id, start_date: '06/09/2018'.to_date, end_date: nil)
        TimeSheet.create(user_id: user.id, project_id: project.id, date: '12/09/2018'.to_date, from_time: '9:00', to_time: '10:00', description: 'Discuss new story')
        HolidayList.create(holiday_date: '13/09/2018'.to_date, reason: 'test')
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(project, from_date, to_date)
        expect(allocated_hours).to eq("9 Days (72H)")
      end
    end

    context "Should calculate allocated hours from searching start date and user's project end date" do
      it 'These is no any holiday' do
        UserProject.create(user_id: user.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: '06/09/2018')
        TimeSheet.create(user_id: user.id, project_id: project.id, date: '04/09/2018'.to_date, from_time: '9:00', to_time: '10:00', description: 'Discuss new story')
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(project, from_date, to_date)
        expect(allocated_hours).to eq("3 Days (24H)")
      end

      it 'These is one holiday' do
        UserProject.create(user_id: user.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: '06/09/2018')
        TimeSheet.create(user_id: user.id, project_id: project.id, date: '04/09/2018'.to_date, from_time: '9:00', to_time: '10:00', description: 'Discuss new story')
        HolidayList.create(holiday_date: '05/09/2018'.to_date, reason: 'test')
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(project, from_date, to_date)
        expect(allocated_hours).to eq("2 Days (16H)")
      end
    end

    context 'Above all scenario' do
      let!(:user_one) { FactoryGirl.create(:user) }
      let!(:user_two) { FactoryGirl.create(:user) }
      let!(:user_three) { FactoryGirl.create(:user) }
      let!(:user_four) { FactoryGirl.create(:user) }

      it 'Should calculate correct allocated hours' do
        UserProject.create(user_id: user_one.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
        UserProject.create(user_id: user_two.id, project_id: project.id, start_date: '05/09/2018'.to_date, end_date: '15/09/2018'.to_date)
        UserProject.create(user_id: user_three.id, project_id: project.id, start_date: '06/09/2018'.to_date, end_date: nil)
        UserProject.create(user_id: user_four.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: '06/09/2018')

        TimeSheet.create(user_id: user_one.id, project_id: project.id, date: '12/09/2018'.to_date, from_time: '9:00', to_time: '10:00', description: 'Discuss new story')
        TimeSheet.create(user_id: user_two.id, project_id: project.id, date: '12/09/2018'.to_date, from_time: '10:00', to_time: '11:00', description: 'Discuss new story')
        TimeSheet.create(user_id: user_three.id, project_id: project.id, date: '11/09/2018'.to_date, from_time: '9:00', to_time: '10:00', description: 'Discuss new story')
        TimeSheet.create(user_id: user_four.id, project_id: project.id, date: '04/09/2018'.to_date, from_time: '9:00', to_time: '10:00', description: 'Discuss new story')

        HolidayList.create(holiday_date: '05/09/2018'.to_date, reason: 'test')
        from_date = '01/09/2018'.to_date
        to_date = '20/09/2018'.to_date
        allocated_hours = TimeSheet.get_allocated_hours(project, from_date, to_date)
        expect(allocated_hours).to eq("31 Days (248H)")
      end
    end
  end

  context 'get leaves count' do
    let!(:user) { FactoryGirl.create(:user, status: STATUS[2]) }
    let!(:project) { FactoryGirl.create(:project, name: 'test') }

    it 'Should calculate leaves between from date and to date' do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
      FactoryGirl.create(:leave_application, user_id: user.id, start_at: '14/09/2018', end_at: '14/09/2018', number_of_days: 1, leave_status: LEAVE_STATUS[1])
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      leave_count = TimeSheet.get_leaves(project, from_date, to_date, 'project')
      expect(leave_count).to eq(1)
    end

    it "Should calculate leaves from user's project start date and end date" do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: '05/09/2018'.to_date, end_date: '15/09/2018'.to_date)
      FactoryGirl.create(:leave_application, user_id: user.id, start_at: '14/09/2018', end_at: '14/09/2018', number_of_days: 1, leave_status: LEAVE_STATUS[1])
      FactoryGirl.create(:leave_application, user_id: user.id, start_at: '13/09/2018', end_at: '13/09/2018', number_of_days: 1, leave_status: LEAVE_STATUS[1])
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      leave_count = TimeSheet.get_leaves(project, from_date, to_date, 'project')
      expect(leave_count).to eq(2)
    end

    it "Should calculate leaves from user's project start date and searching to date" do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: '06/09/2018'.to_date, end_date: nil)
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      FactoryGirl.create(:leave_application, user_id: user.id, start_at: '14/09/2018', end_at: '14/09/2018', number_of_days: 1, leave_status: LEAVE_STATUS[1])
      FactoryGirl.create(:leave_application, user_id: user.id, start_at: '13/09/2018', end_at: '13/09/2018', number_of_days: 1, leave_status: LEAVE_STATUS[1])
      leave_count = TimeSheet.get_leaves(project, from_date, to_date, 'project')
      expect(leave_count).to eq(2)
    end

    it "Should calculate leaves from searching start date and user's project end date" do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: '06/09/2018')
      from_date = '01/09/2018'.to_date
      to_date = '20/09/2018'.to_date
      FactoryGirl.create(:leave_application, user_id: user.id, start_at: '03/09/2018', end_at: '03/09/2018', number_of_days: 1, leave_status: LEAVE_STATUS[1])
      FactoryGirl.create(:leave_application, user_id: user.id, start_at: '13/09/2018', end_at: '13/09/2018', number_of_days: 1, leave_status: LEAVE_STATUS[1])
      leave_count = TimeSheet.get_leaves(project, from_date, to_date, 'project')
      expect(leave_count).to eq(1)
    end
  end

  context 'approved leaves count for weekly report' do
    let!(:user) { FactoryGirl.create(:user, status: STATUS[2]) }
    let!(:project) { FactoryGirl.create(:project, name: 'test') }

    it 'Should give approved leaves count' do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
      FactoryGirl.create(:leave_application, user_id: user.id, start_at: '12/11/2018', end_at: '15/11/2018', number_of_days: 4, leave_status: LEAVE_STATUS[1])
      from_date = '12/11/2018'.to_date
      to_date = '18/11/2018'.to_date
      leaves_count = TimeSheet.approved_leaves_count_for_weekly_report(user, from_date, to_date)
      expect(leaves_count).to eq(4)
    end

    it "Should give approved leaves and doesn't consider holiday in it" do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
      FactoryGirl.create(:leave_application, user_id: user.id, start_at: '12/11/2018', end_at: '15/11/2018', number_of_days: 4, leave_status: LEAVE_STATUS[1])
      HolidayList.create(holiday_date: '14/11/2018', reason: 'test')
      from_date = '12/11/2018'.to_date
      to_date = '18/11/2018'.to_date
      leaves_count = TimeSheet.approved_leaves_count_for_weekly_report(user, from_date, to_date)
      expect(leaves_count).to eq(3)
    end
  end

  context 'Project report' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project) }

    it 'Should give expected project report' do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 20, end_date: nil)
      TimeSheet.create(user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: "#{Date.today - 1} 19:00", to_time: "#{Date.today - 1} 20:00", description: 'Discuss new story')
      HolidayList.create(holiday_date: Date.today - 4, reason: 'test')
      FactoryGirl.create(:leave_application, user_id: user.id, start_at: Date.today - 2, end_at: Date.today - 2, number_of_days: 1)

      from_date = Date.today - 20
      to_date = Date.today
      load_projects_report = TimeSheet.load_projects_report(from_date, to_date)
      projects_report, project_without_timesheet, users_without_timesheet = TimeSheet.create_projects_report_in_json_format(load_projects_report, from_date, to_date)
      expect(projects_report[0]["project_name"]).to eq("The pediatric network")
      expect(projects_report[0]["no_of_employee"]).to eq(1)
      expect(projects_report[0]["total_hours"]).to eq("0 Days 1H (1H)")
      expect(projects_report[0]["allocated_hours"]).to eq("13 Days (104H)")
      expect(projects_report[0]["leaves"]).to eq(1)
      expect(project_without_timesheet.present?).to eq(false)
      expect(users_without_timesheet.count).to eq(0)
    end

    it 'Should give project without timesheet' do
      test_project_one = FactoryGirl.create(:project, name: 'test1', timesheet_mandatory: true)
      test_project_two = FactoryGirl.create(:project, name: 'test2', timesheet_mandatory: true)
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 20, end_date: nil)
      UserProject.create(user_id: user.id, project_id: test_project_one.id, start_date: Date.today - 20, end_date: nil)
      TimeSheet.create(user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: "#{Date.today - 1} 9:00", to_time: "#{Date.today - 1} 10:00", description: 'Discuss new story')
      from_date = Date.today - 30
      to_date = Date.today - 1
      load_projects_report = TimeSheet.load_projects_report(from_date, to_date)
      projects_report, project_without_timesheet, users_without_timesheet = TimeSheet.create_projects_report_in_json_format(load_projects_report, from_date, to_date)
      expect(project_without_timesheet.count).to eq(2)
      expect(project_without_timesheet[0]['project_name']).to eq('test1')
      expect(project_without_timesheet[1]['project_name']).to eq('test2')
    end

    it 'Should give users without timesheet' do
      user_two = FactoryGirl.create(:user, email: 'user_one@joshsoftware.com', role: 'Employee', status: STATUS[2])
      user_three = FactoryGirl.create(:user, email: 'user_two@joshsoftware.com', role: 'Intern', status: STATUS[2])

      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 20, end_date: nil)
      UserProject.create(user_id: user_two.id, project_id: project.id, start_date: Date.today - 20, end_date: nil)
      UserProject.create(user_id: user_three.id, project_id: project.id, start_date: Date.today - 20, end_date: nil)
      
      TimeSheet.create(user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: "#{Date.today - 1} 21:00", to_time: "#{Date.today - 1} 22:00", description: 'Discuss new story')
      from_date = Date.today - 20
      to_date = Date.today
      load_projects_report = TimeSheet.load_projects_report(from_date, to_date)
      projects_report, project_without_timesheet, users_without_timesheet = TimeSheet.create_projects_report_in_json_format(load_projects_report, from_date, to_date)
      expect(users_without_timesheet[0].email).to eq(users_without_timesheet[0].email)
      expect(users_without_timesheet[1].email).to eq(users_without_timesheet[1].email)
    end
  end

  context 'Individual project report' do
    let!(:user_one) { FactoryGirl.create(:user) }
    let!(:user_two) { FactoryGirl.create(:user) }
    let!(:user_three) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project) }

    it 'Should give the expected project report' do
      user_one.public_profile.update_attributes(first_name: 'test1_user', last_name: 'test1_user')
      user_two.public_profile.update_attributes(first_name: 'test2_user', last_name: 'test2_user')
      user_three.public_profile.update_attributes(first_name: 'test3_user', last_name: 'test3_user')
      UserProject.create(user_id: user_one.id, project_id: project.id, start_date: '01/08/2018'.to_date, end_date: nil)
      UserProject.create(user_id: user_two.id, project_id: project.id, start_date: '06/09/2018'.to_date, end_date: nil)

      TimeSheet.create(user_id: user_one.id, project_id: project.id, date: Date.today - 1, from_time: "#{Date.today - 1} 21:00", to_time: "#{Date.today - 1} 22:00", description: 'Worked on test cases')
      TimeSheet.create(user_id: user_one.id, project_id: project.id, date: Date.today - 1, from_time: "#{Date.today - 1} 8:00", to_time: "#{Date.today - 1} 9:00", description: 'Worked on test cases')
      TimeSheet.create(user_id: user_one.id, project_id: project.id, date: Date.today - 2, from_time: "#{Date.today - 1} 21:00", to_time: "#{Date.today - 1} 22:00", description: 'Worked on test cases')
      FactoryGirl.create(:leave_application, user_id: user_one.id, start_at: Date.today - 10, end_at: Date.today - 7, number_of_days: 3)

      TimeSheet.create(user_id: user_two.id, project_id: project.id, date: Date.today - 1, from_time: "#{Date.today - 1} 21:00", to_time: "#{Date.today - 1} 22:00", description: 'Worked on test cases')
      TimeSheet.create(user_id: user_two.id, project_id: project.id, date: Date.today - 1, from_time: "#{Date.today - 1} 8:00", to_time: "#{Date.today - 1} 10:00", description: 'Worked on test cases')

      FactoryGirl.create(:leave_application, user_id: user_three.id, start_at: '12/09/2018', end_at: '13/09/2018', number_of_days: 2)

      params = { from_date: Date.today - 20, to_date: Date.today }
      individual_project_report, project_report = TimeSheet.generate_individual_project_report(project, params)

      expect(individual_project_report['test1_user test1_user'][0]['total_work']).to eq('0 Days 3H (3H)')
      expect(individual_project_report['test1_user test1_user'][0]['allocated_hours']).to eq('14 Days (112H)')
      expect(individual_project_report['test1_user test1_user'][0]['leaves']).to eq(3)

      expect(individual_project_report['test2_user test2_user'][0]['total_work']).to eq('0 Days 3H (3H)')
      expect(individual_project_report['test2_user test2_user'][0]['allocated_hours']).to eq('14 Days (112H)')
      expect(individual_project_report['test2_user test2_user'][0]['leaves']).to eq(0)

      expect(project_report['total_worked_hours']).to eq('0 Days 6H (6H)')
      expect(project_report['total_allocated_hourse']).to eq('28 Days (224H)')
      expect(project_report['total_leaves']).to eq(3)
    end
  end

  context 'Generate weekly report in csv format' do
    it 'Should generate csv' do
      weekly_report = [
                        ['employee_test1', 'project_test1', '0 days 6H (6H)', 1, 0], 
                        ['employee_test2', 'project_test2', '0 days 3H (3H)', 2, 1]
                      ]
      csv = TimeSheet.generate_weekly_report_in_csv_format(weekly_report)
      expect(csv).to eq("Employee name,Project name,No of days worked,Leaves,Holidays\nemployee_test1,project_test1,0 days 6H (6H),1,0\nemployee_test2,project_test2,0 days 3H (3H),2,1\n")
    end
  end

  context 'Get holiday count' do
    it 'Should give holiday count' do
      HolidayList.create(holiday_date: '09/10/2018'.to_date, reason: 'test')
      HolidayList.create(holiday_date: '11/10/2018'.to_date, reason: 'test')
      from_date = '05/10/2018'.to_date
      to_date = '15/10/2018'.to_date
      count = TimeSheet.get_holiday_count(from_date, to_date)
      expect(count).to eq(2)
    end

    it 'Should give holiday count 0' do
      HolidayList.create(holiday_date: '09/10/2018'.to_date, reason: 'test')
      HolidayList.create(holiday_date: '11/10/2018'.to_date, reason: 'test')
      from_date = '01/10/2018'.to_date
      to_date = '05/10/2018'.to_date
      count = TimeSheet.get_holiday_count(from_date, to_date)
      expect(count).to eq(0)
    end
  end

  context 'Get time sheet and calculate total minutes' do
    let!(:user) { FactoryGirl.create(:user) }
    it 'Should give total working minutes' do
      project = FactoryGirl.create(:project)
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)

      TimeSheet.create(user_id: user.id, project_id: project.id, date: DateTime.now - 1, from_time: Time.parse("#{Date.today - 1} 10"), to_time: Time.parse("#{Date.today - 1} 11"), description: 'test')
      TimeSheet.create(user_id: user.id, project_id: project.id, date: DateTime.now - 1, from_time: Time.parse("#{Date.today - 1} 11"), to_time: Time.parse("#{Date.today - 1} 12"), description: 'test')
      TimeSheet.create(user_id: user.id, project_id: project.id, date: DateTime.now - 1, from_time: Time.parse("#{Date.today - 1} 12"), to_time: Time.parse("#{Date.today - 1} 13"), description: 'test')

      from_date = Date.today - 3
      to_date = Date.today + 3
      total_minutes, users_without_timesheet = TimeSheet.get_time_sheet_and_calculate_total_minutes(user, project, from_date, to_date, 0)
      expect(total_minutes).to eq(180.0)
    end

    it 'Should give the users without timesheet because user role is employee' do
      project = FactoryGirl.create(:project)
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      leave_application = 
      user.leave_applications.create(start_at: Date.today - 1, end_at: Date.today- 1, contact_number: '1234567890', number_of_days: 1, reason: 'test', leave_status: LEAVE_STATUS[1])
      from_date = Date.today - 3
      to_date = Date.today + 3
      total_minutes, users_without_timesheet = TimeSheet.get_time_sheet_and_calculate_total_minutes(user, project, from_date, to_date, leave_application.number_of_days)
      expect(total_minutes).to eq(0)
      expect(users_without_timesheet).to eq(["fname lname", "The pediatric network", 1])
    end

    it 'Should give users without timesheet because role is intern' do
      project = FactoryGirl.create(:project)
      user_two = FactoryGirl.create(:user, role: 'Intern')
      UserProject.create(user_id: user_two.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      from_date = Date.today - 3
      to_date = Date.today + 3
      total_minutes, users_without_timesheet = TimeSheet.get_time_sheet_and_calculate_total_minutes(user_two, project, from_date, to_date, 0)
      expect(total_minutes).to eq(0)
      expect(users_without_timesheet).to eq(["fname lname", "The pediatric network", 0])
    end

    it 'Should not give the uses without timesheet because user role is manager' do
      project = FactoryGirl.create(:project)
      user_two = FactoryGirl.create(:user, role: 'Manager')
      UserProject.create(user_id: user_two.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      from_date = Date.today - 3
      to_date = Date.today + 3
      total_minutes, users_without_timesheet = TimeSheet.get_time_sheet_and_calculate_total_minutes(user_two, project, from_date, to_date, 0)
      expect(users_without_timesheet.present?).to eq(false)
    end

    it 'Should not give the uses without timesheet because user role is admin' do
      project = FactoryGirl.create(:project, timesheet_mandatory: true)
      user_two = FactoryGirl.create(:user, role: 'Admin')
      UserProject.create(user_id: user_two.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      from_date = Date.today - 3
      to_date = Date.today + 3
      total_minutes, users_without_timesheet = TimeSheet.get_time_sheet_and_calculate_total_minutes(user_two, project, from_date, to_date, 0)
    end

    it "Should consider project for calculating total minutes if project's timesheet mandatory field set to false" do
      project_other = FactoryGirl.create(:project, name: 'Other', timesheet_mandatory: false)
      UserProject.create(user_id: user.id, project_id: project_other.id, start_date: Date.today - 10, end_date: nil)
      TimeSheet.create!(user_id: user.id, project_id: project_other.id, date: DateTime.now, from_time: Time.parse("#{Date.today} 8"), to_time: Time.parse("#{Date.today} 9"), description: 'test')
      from_date = Date.today - 3
      to_date = Date.today + 3
      total_minutes, users_without_timesheet = TimeSheet.get_time_sheet_and_calculate_total_minutes(user, project_other, from_date, to_date, 0)
      expect(total_minutes).to eq(60.0)
    end

    it 'Should not consider project whose timesheet mandatory field set to false for users without timesheet list' do
      project_other = FactoryGirl.create(:project, name: 'Other', timesheet_mandatory: false)
      UserProject.create(user_id: user.id, project_id: project_other.id, start_date: Date.today - 10, end_date: nil)
      TimeSheet.create!(user_id: user.id, project_id: project_other.id, date: DateTime.now, from_time: Time.parse("#{Date.today} 8"), to_time: Time.parse("#{Date.today} 9"), description: 'test')
      from_date = Date.today - 3
      to_date = Date.today + 3
      total_minutes, users_without_timesheet = TimeSheet.get_time_sheet_and_calculate_total_minutes(user, project_other, from_date, to_date, 0)
      expect(users_without_timesheet.present?).to eq(false)
    end
  end

  context 'Update timesheet' do
    let!(:user) { FactoryGirl.create(:user, email: 'abc@joshsoftware.com', role: 'Admin') }
    let!(:project) { FactoryGirl.create(:project, name: 'test') }
  
    it 'Should give return value true' do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      time_sheet = TimeSheet.create(user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: Time.parse("#{Date.today - 1} 10"), to_time: Time.parse("#{Date.today - 1} 11:30"), description: 'Woked on test cases')
      params = {"time_sheets_attributes"=>{"0"=>{"project_id"=>"#{project.id}", "date"=>"#{Date.today - 1}", "from_time"=>"#{Date.today - 1} - 09:00 AM", "to_time"=>"#{Date.today - 1} - 11:15 AM", "description"=>"testing API and call with client", "id"=>"#{time_sheet.id}"}}, "id"=>user.id}
      return_value = TimeSheet.check_validation_while_updating_time_sheet(params)
      expect(return_value).to eq(true)
    end
  
    it 'Should give error from time less than to time' do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      time_sheet = TimeSheet.create(user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: Time.parse("#{Date.today - 1} 10"), to_time: Time.parse("#{Date.today - 1} 11:30"), description: 'Woked on test cases')
      params = {"time_sheets_attributes"=>{"0"=>{"project_id"=>"#{project.id}", "date"=>"#{Date.today - 1}", "from_time"=>"#{Date.today - 1} - 10:00 AM", "to_time"=>"#{Date.today - 1} - 09:00 AM", "description"=>"", "id"=>"#{time_sheet.id}"}}, "id"=>user.id}
      return_value = TimeSheet.check_validation_while_updating_time_sheet(params)
      expect(return_value).to eq("Error :: From time must be less than to time")
    end
  
    it 'Should give error not allowed to fill timesheet for this date. If you want to fill the timesheet, meet your manager' do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      time_sheet = TimeSheet.create(user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: Time.parse("#{Date.today - 1} 10"), to_time: Time.parse("#{Date.today - 1} 11:30"), description: 'Woked on test cases')
      params = {"time_sheets_attributes"=>{"0"=>{"project_id"=>"", "date"=>"#{Date.today - 10}", "from_time"=>"#{Date.today - 1} - 09:00 AM", "to_time"=>"#{Date.today - 1} - 11:15 AM", "description"=>"", "id"=>"#{time_sheet.id}"}}, "id"=>user.id}
      return_value = TimeSheet.check_validation_while_updating_time_sheet(params)
      expect(return_value).to eq('Error :: Not allowed to fill timesheet for this date. If you want to fill the timesheet, meet your manager.')
    end
  
    it "Should give error can't fill the timesheet for future time" do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      time_sheet = TimeSheet.create(user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: Time.parse("#{Date.today - 1} 10"), to_time: Time.parse("#{Date.today - 1} 11:30"), description: 'Woked on test cases')
      params = {"time_sheets_attributes"=>{"0"=>{"project_id"=>"", "date"=>"#{Date.today}", "from_time"=>"#{DateTime.now + 3.minutes}", "to_time"=>"#{DateTime.now + 5.minutes}", "description"=>"", "id"=>"#{time_sheet.id}"}}, "id"=>user.id}
      return_value = TimeSheet.check_validation_while_updating_time_sheet(params)
      expect(return_value).to eq("Error :: Can't fill the timesheet for future time.")
    end
  
    it 'Should give error not allowed to fill timesheet for this date. If you want to fill the timesheet, meet your manager.' do
      UserProject.create(user_id: user.id, project_id: project.id, start_date: Date.today - 10, end_date: nil)
      time_sheet = TimeSheet.create(user_id: user.id, project_id: project.id, date: Date.today - 1, from_time: Time.parse("#{Date.today - 1} 10"), to_time: Time.parse("#{Date.today - 1} 11:30"), description: 'Woked on test cases')
      params = {"time_sheets_attributes"=>{"0"=>{"project_id"=>"", "date"=>"#{Date.today - 10}", "from_time"=>"#{DateTime.now + 3.minutes}", "to_time"=>"#{DateTime.now + 5.minutes}", "description"=>"", "id"=>"#{time_sheet.id}"}}, "id"=>user.id}
      return_value = TimeSheet.check_validation_while_updating_time_sheet(params)
      expect(return_value).to eq('Error :: Not allowed to fill timesheet for this date. If you want to fill the timesheet, meet your manager.')
    end
  end

  context 'Export project report' do
    let!(:user_one) { FactoryGirl.create(:user) }
    let!(:user_two) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project) }
    
    it 'Should give the project report' do
      UserProject.create(user_id: user_one.id, project_id: project.id, start_date: Date.today - 20, end_date: nil)
      UserProject.create(user_id: user_two.id, project_id: project.id, start_date: Date.today - 20, end_date: nil)
      user_one.time_sheets.create!(project_id: project.id, date: Date.today - 2, from_time: "#{Date.today - 2} 10", to_time: "#{Date.today - 2} 11", description: 'Test api')
      user_one.time_sheets.create!(project_id: project.id, date: Date.today - 2, from_time: "#{Date.today - 2} 12", to_time: "#{Date.today - 2} 13", description: 'call with client')
      user_two.time_sheets.create!(project_id: project.id, date: Date.today - 2, from_time: "#{Date.today - 2} 10", to_time: "#{Date.today - 2} 11", description: 'test data')
      from_date = Date.today - 20
      to_date = Date.today
      project_report = TimeSheet.create_project_report_in_csv(project, from_date, to_date)
      expect(project_report).to eq("Employee name,Date(dd/mm/yyyy),No of hours,Details\nfname lname,28-10-2018,2,\"Test api\ncall with client\"\nfname lname,28-10-2018,1,test data\n")
    end
  end

  context 'Api test' do
    it 'Invalid time sheet format : Should return true ' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: Invalid timesheet format. Fromat should be <project_name> <date> <from_time> <to_time> <description>\`"
      }
      VCR.use_cassette 'timesheet_failure_reason_invalid_date' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'Not assigned project : Should return true' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: you are not working on this project. Use /projects command to view your project\`"
      }
      VCR.use_cassette 'timesheet_failure_reason_not_assign_project' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'Invalid date format : Should return true' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: Invalid date format. Format should be dd/mm/yyyy\`"
      }
      VCR.use_cassette 'timesheet_failure_reason_invalid_date_format' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'Date range : Should return true' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: Date should be in last week\`"
      }
      VCR.use_cassette 'timesheet_failure_reason__date_in_last_week' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'Date range : Should return true' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: Date should be in last week\`"
      }
      VCR.use_cassette 'timesheet_failure_reason__date_in_last_week' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'From time should be less than to time : Should return true' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: From time must be less than to time\`"
      }
      VCR.use_cassette 'timesheet_failure_reason__from_time_is_less' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'From time should be less than to time : Should return true' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: From time must be less than to time\`"
      }
      VCR.use_cassette 'timesheet_failure_reason__from_time_is_less' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'Invalid time format : Should return true' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: Invalid time format. Format should be HH:MM\`"
      }
      VCR.use_cassette 'timesheet_failure_reason__invalid_time' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'Record is already present : should return true' do
      text = "\` Error :: From time record is already present, To time record is already present\`"
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => text
      }
      VCR.use_cassette 'timesheet_failure_reason_record_already_present' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        ret = JSON.parse(response.body)
        expect(ret['ok']).to eq(true)
      end
    end

    it 'Should return false because invalid slack token' do
      slack_params = {
        'token' => 'abcd.efghi.gklmno',
        'channel' => CHANNEL_ID,
        'text' => "\`Error :: Invalid time format\`"
      }
      VCR.use_cassette 'timesheet_failure_reason_invalid_slack_token' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        resp = JSON.parse(response.body)
        expect(resp['ok']).to eq(false)
        expect(resp['error']).to eq('invalid_auth')
      end
    end

    it 'Should return false because invalid channel id' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => 'UU12345',
        'text' => "\`Error :: Channel not found\`"
      }
      VCR.use_cassette 'timesheet_failure_reason_invalid_channel_id' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        resp = JSON.parse(response.body)
        expect(resp['ok']).to eq(false)
        expect(resp['error']).to eq('channel_not_found')
      end
    end

    it 'Should return false because text is empty' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'channel' => CHANNEL_ID,
        'text' => ""
      }
      VCR.use_cassette 'timesheet_failure_reason_empty_text' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/chat.postMessage"), slack_params)
        resp = JSON.parse(response.body)
        expect(resp['ok']).to eq(false)
        expect(resp['error']).to eq('no_text')
      end
    end

    it 'Should return true because user id is valid' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'user' => USER_ID
      }
      VCR.use_cassette 'success_user_info' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/users.info"), slack_params)
        resp = JSON.parse(response.body)
        expect(resp['ok']).to eq(true)
      end
    end

    it 'Should return false because user id is invalid' do
      slack_params = {
        'token' => SLACK_API_TOKEN,
        'user' => 'ABCD8F'
      }
      VCR.use_cassette 'failure_user_info' do
        response = Net::HTTP.post_form(URI("https://slack.com/api/users.info"), slack_params)
        resp = JSON.parse(response.body)
        expect(resp['ok']).to eq(false)
        expect(resp['error']).to eq('user_not_found')
      end
    end

    context 'im open API' do
      it 'Should success to create new channel and closed that channel' do
        new_channel = ''
        slack_params_for_im_open = {
          'token' => SLACK_API_TOKEN,
          'user' => USER_ID
        }

        VCR.use_cassette('success_im_open') do
          response = Net::HTTP.post_form(URI("https://slack.com/api/im.open"), slack_params_for_im_open)
          resp = JSON.parse(response.body)
          new_channel = resp['channel']['id']
          expect(resp['ok']).to eq(true)
          expect(new_channel.present?).to eq(true)
        end

        slack_params_for_im_close = {
          'token' => SLACK_API_TOKEN,
          'channel' => new_channel
        }

        VCR.use_cassette('success_im_close') do
          response = Net::HTTP.post_form(URI("https://slack.com/api/im.close"), slack_params_for_im_close)
          resp = JSON.parse(response.body)
          expect(resp['ok']).to eq(true)
        end
      end

      context 'failure' do
        it 'Should fail im open api because user id invalid' do
          slack_params = {
            'token' => SLACK_API_TOKEN,
            'user' => 'ABC123'
          }

          VCR.use_cassette 'failure_im_open_reason_invalid_user_id' do
            response = Net::HTTP.post_form(URI("https://slack.com/api/im.open"), slack_params)
            resp = JSON.parse(response.body)
            expect(resp['ok']).to eq(false)
            expect(resp['error']).to eq('user_not_found')
          end
        end

        it 'Should fail im open api because invalid slack token' do
          slack_params = {
            'token' => 'abcd12 wert345 qsrt432',
            'user' => 'ABC123'
          }

          VCR.use_cassette 'failure_im_open_reason_invalid_slack_token' do
            response = Net::HTTP.post_form(URI("https://slack.com/api/im.open"), slack_params)
            resp = JSON.parse(response.body)
            expect(resp['ok']).to eq(false)
            expect(resp['error']).to eq('invalid_auth')
          end
        end

        it 'Should fail im close api because invalid channel id' do
          slack_params = {
            'token' => SLACK_API_TOKEN,
            'channel' => 'DE12345'
          }

          VCR.use_cassette 'failure_im_close_reason_invlid_channel_id' do
            response = Net::HTTP.post_form(URI("https://slack.com/api/im.close"), slack_params)
            resp = JSON.parse(response.body)
            expect(resp['ok']).to eq(false)
            expect(resp['error']).to eq('channel_not_found')
          end
        end

        it 'Should fail im close api because invalid slack token' do
          slack_params = {
            'token' => 'abcd12 wert345 qsrt432',
            'channel' => 'DE12345'
          }

          VCR.use_cassette 'failure_im_close_reason_invlid_slack_token' do
            response = Net::HTTP.post_form(URI("https://slack.com/api/im.close"), slack_params)
            resp = JSON.parse(response.body)
            expect(resp['ok']).to eq(false)
            expect(resp['error']).to eq('invalid_auth')
          end
        end
      end
    end
  end
end
