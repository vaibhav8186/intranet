class SlackBot < SlackRubyBot::Bot
  include Mongoid::Document
  include CheckUser

  def prepend_index(projects)
    "#{projects.each_with_index.map{|project, index| project.prepend("#{index+1}. ")}.join("\n")}"
  end

  def fetch_email_and_associate_to_user(user_id)
    call_slack_api_service_and_fetch_email(user_id)
  end
end
