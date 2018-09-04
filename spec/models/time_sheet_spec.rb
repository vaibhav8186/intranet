require 'rails_helper'

RSpec.describe TimeSheet, type: :model do
  context 'Validation' do
    let!(:user) { FactoryGirl.create(:user) }
    # let!(:user) { user.projects.create(:project)}
    let!(:time_sheet) { FactoryGirl.build(:time_sheet) }

    before do
      user.public_profile.slack_handle = USER_ID
      user.projects.create(name: 'England Hockey', display_name: 'England_Hockey')
      user.save
      stub_request(:post, "https://slack.com/api/chat.postMessage")
    end

    it 'Should success' do
      params = {
        'user_id' => USER_ID, 
        'channel_id' => CHANNEL_ID, 
        'text' => "England_Hockey #{Date.yesterday}  6 7 abcd efghigk lmnop"
      }

      ret = time_sheet.parse_timesheet_data(params)
      expect(ret[0]).to eq(true)
    end

    it 'Should success even if project name is lower case' do
      params = {
        'user_id' => USER_ID,
        'channel_id' => CHANNEL_ID,
        'text' => "england_hockey #{Date.yesterday}  6 7 abcd efghigk lmnop"
      }

      ret = time_sheet.parse_timesheet_data(params)
      expect(ret[0]).to eq(true)
    end

    it 'Should fails because record is already present' do
      time_sheet = FactoryGirl.create(:time_sheet)
      time_sheet_test = FactoryGirl.build(:time_sheet)
      time_sheet_test.save
      expect(time_sheet_test.errors.full_messages).to eq(["From time record is already present", "To time record is already present"])
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

      it 'Should return false because date is not within this week' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => 'England_Hockey 1/07/2018  6 7 abcd efgh'
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end

      it 'Should return false because date is invalid' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => 'England_Hockey 1/32/2018  6 7 abcd efgh'
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end

      it 'Should return false because date and time is greater than current date and time' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => "England_Hockey #{Date.today}  20:00 20:30 abcd efgh"
        }

        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end
    end

    context 'Validation - Time' do
      it 'Should return false because invalid from time format' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => "England_Hockey #{Date.yesterday} 15.30 16 abcd efgh"
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end

      it 'Should return false because invalid to time format' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => "England_Hockey #{Date.yesterday} 6 7.00 abcd efgh"
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end

      it 'Should return false because from time is greater than to time' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => "England_Hockey #{Date.yesterday} 8 7 abcd efgh"
        }
        expect(time_sheet.parse_timesheet_data(params)).to eq(false)
      end
    end
  end

  context 'Timesheet reminder' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:time_sheet) { FactoryGirl.build(:time_sheet) }

    before do
      user.public_profile.slack_handle = USER_ID
    end

    context 'check timesheet' do
      it 'Should return false because timesheet is not present' do
        expect(time_sheet.check_time_sheet(user)).to eq(false)
      end

      it 'should return true because timesheet is present' do
        user.time_sheets.create(date: 1.days.ago, from_time: '9:00', to_time: '10:00', description: 'Today I finish the work')
        expect(time_sheet.check_time_sheet(user)).to eq(true)
      end
    end

    context 'timesheet filled' do
      before do
        user.time_sheets.create(date: Date.today - 1, from_time: '9:00', to_time: '10:00', description: 'Today I finish the work')
        user.time_sheets.create(date: Date.today - 2, from_time: '9:00', to_time: '10:00', description: 'Today I finish the work')
        user.time_sheets.create(date: Date.today - 3, from_time: '9:00', to_time: '10:00', description: 'Today I finish the work')
      end

      it 'Should return false because timesheet is not filled' do
        expect(time_sheet.time_sheet_filled?(user, 4.days.ago.utc)).to eq(false)
      end

      it 'Should return true because timesheet is filled' do
        expect(time_sheet.time_sheet_filled?(user, Date.today - 1)).to eq(true)
      end
    end

    context 'user on leave' do
      it 'Should return false because leave application is not present' do
        expect(time_sheet.user_on_leave?(user, Date.today - 2)).to eq(false)
      end

      it 'Should return true because user is on leave' do
        FactoryGirl.create(:leave_application, user_id: user.id)
        expect(time_sheet.user_on_leave?(user, Date.today + 2)).to eq(true)
      end

      it 'Should return false because user is not on leave' do
        FactoryGirl.create(:leave_application, user_id: user.id)
        expect(time_sheet.user_on_leave?(user, Date.today + 4)).to eq(false)
      end
    end
  end

  context 'Daily timesheet status' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { user.projects.create(name: 'The pediatric network', display_name: 'The_pediatric_network') }
    let!(:time_sheet) { FactoryGirl.build(:time_sheet) }

    before do
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

        time_sheets = time_sheet.parse_daily_status_command(params)
        expect(time_sheets).to eq("#{time_sheets}")
      end

      it 'Should return false because timesheet record not present' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => ""
        }

        time_sheets = time_sheet.parse_daily_status_command(params)
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
          'text' => Date.yesterday.to_s
        }
        time_sheets = time_sheet.parse_daily_status_command(params)
        expect(time_sheets).to eq("#{time_sheets}")
      end

      it 'Should return false because timesheet record not present' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => Date.yesterday.to_s
        }
        time_sheets = time_sheet.parse_daily_status_command(params)
        expect(time_sheets).to eq(false)
      end

      it 'Should return false because invalid date format' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => '06/07'
        }

        time_sheets = time_sheet.parse_daily_status_command(params)
        expect(time_sheets).to eq(false)
      end

      it 'Should return false because invalid date' do
        params = {
          'user_id' => USER_ID,
          'channel_id' => CHANNEL_ID,
          'text' => '06/13/2018'
        }

        time_sheets = time_sheet.parse_daily_status_command(params)
        expect(time_sheets).to eq(false)
      end
    end

    it 'Should give right hours and minutes' do
      total_minutes = 359
      local_var_hours = total_minutes / 60
      local_var_minutes = total_minutes % 60
      hours, minutes = time_sheet.calculate_hours_and_minutes(total_minutes)
      expect(hours).to eq(local_var_hours)
      expect(minutes).to eq(local_var_minutes)
    end

    it 'Should give right difference between time' do
      user.time_sheets.create(user_id: user.id, project_id: project.id, 
                              date: DateTime.yesterday, from_time: Time.parse("#{Date.yesterday} 9:00"), 
                              to_time: Time.parse("#{Date.yesterday} 10:00"), description: 'Today I finish the work')
      user_time_sheet = user.time_sheets[0]
      time_diff = TimeDifference.between(user_time_sheet.to_time, user_time_sheet.from_time).in_minutes
      minutes = time_sheet.calculate_working_minutes(user_time_sheet)
      expect(minutes).to eq(time_diff)
    end
  end

  context 'Employee timesheet report' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:time_sheet) { FactoryGirl.build(:time_sheet) }
    let!(:project) { user.projects.create(name: 'The pediatric network', display_name: 'The_pediatric_network') }

    it 'Should give the project name' do
      expect(TimeSheet.get_project_name(project.id)).to eq(project.name)
    end

    it 'Should give the correct hours and minutes' do
      milliseconds = 7200000
      local_var_hours = milliseconds / (1000 * 60 * 60)
      local_var_minutes = milliseconds / (1000 * 60) % 60
      expect(TimeSheet.convert_milliseconds_to_hours(milliseconds)).to eq("#{local_var_hours}H #{local_var_minutes}M") 
    end

    it 'Should give the user leaves count' do
      FactoryGirl.create(:leave_application, user_id: user.id)
      expect(TimeSheet.get_user_leaves_count(user, Date.today + 2, Date.today + 3)).to eq(1)
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
      timesheet_record = TimeSheet.load_timesheet(Date.yesterday - 1, Date.today)
      timesheet_data = TimeSheet.generete_employee_timesheet_report(timesheet_record, Date.yesterday - 1, Date.today)
      expect(timesheet_data[0]['user_name']).to eq('fname lname')
      expect(timesheet_data[0]['project_details'][0]['project_name']).to eq('The pediatric network')
      expect(timesheet_data[0]['project_details'][0]['worked_hours']).to eq('1H 0M')
      expect(timesheet_data[0]['total_worked_hours']).to eq('1H 0M')
      expect(timesheet_data[0]['leaves']).to eq(0)
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
  end
end
