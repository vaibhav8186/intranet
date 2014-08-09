class MonthlyPaidLeaveWorker
  include Sidekiq::Worker
  sidekiq_options :backtrace => true

  def perform
    eligible_users = User.approved.select{|user| user.eligible_for_leave?}.sort_by(&:email)
    file = Tempfile.new(["intranet_users_leave", '.csv'])
    CSV.open(file.path, 'w') do |csv|
      csv << ['Email', 'Leaves By Monthly Increment']
      eligible_users.each do |user|
        csv << [user.email, user.leave_details.detect{|ld| ld.year == Date.today.year}.try(:available_leave)]
      end
    end
    UserMailer.delay.leaves_before_monthly_increment(file.path)
    eligible_users.each do|u|
      u.assign_monthly_leave 
    end

  end
end
