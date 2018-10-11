class WeeklyTimesheetReportMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com',
          :reply_to => 'hr@joshsoftware.com'
  
  def send_weekly_timesheet_report(csv, email, users_without_timesheet)
    byebug
    attachments["weekly_timesheet_report_#{Date.today}.csv"] = csv
    mail(subject: 'Weekly timesheet report', to: email)
  end
end
