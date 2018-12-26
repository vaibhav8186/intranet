class WeeklyTimesheetReportMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com',
          :reply_to => 'hr@joshsoftware.com'
  
  def send_weekly_timesheet_report(csv, email, unfilled_time_sheet_report)
    @unfilled_time_sheet_report = unfilled_time_sheet_report
    attachments["weekly_timesheet_report_#{Date.today}.csv"] = csv
    mail(subject: 'Weekly timesheet report', to: [email] + DEFAULT_TIMESHEET_MANAGERS)
  end
end
