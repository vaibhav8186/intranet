class TimesheetRemainderMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com',
          :reply_to => 'hr@joshsoftware.com'
  
  def send_timesheet_reminder_mail(user, slack_id, text)
    managers_emails = []
    @user = user
    @text = text
    managers_emails = @user.get_managers_emails
    mail(subject: 'Timesheet Reminder', to: user.email, cc: managers_emails)
  end
end
