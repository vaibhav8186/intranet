class SlackBot < SlackRubyBot::Bot
  include Mongoid::Document
  include CheckUser

  def show_projects(projects, channel)
    text = "#{projects.each_with_index.map{|project, index| project.prepend("#{index+1}. ")}.join("\n")}"
    SlackApiService.new.post_message_to_slack(channel, text)
  end

  def fetch_email_and_associate_to_user(user_id)
    call_slack_api_service_and_fetch_email(user_id)
  end
end
