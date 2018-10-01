class TimesheetRemainderMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com'
  
  def send_timesheet_reminder_mail(slack_id, text)
    managers_emails = []
    @user = User.where("public_profile.slack_handle" => slack_id).first
    @text = text
    managers_emails = @user.get_managers_emails
    mail(subject: 'Timesheet Remainder', to: @user.email, cc: managers_emails)
  end
end
