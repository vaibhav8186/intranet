class SlackBot < SlackRubyBot::Bot
  include Mongoid::Document
  include CheckUser

  def show_projects(projects, channel)
    text = "#{projects.each_with_index.map{|project, index| project.prepend("#{index+1}. ")}.join("\n")}"
    SlackApiService.new.post_message_to_slack(channel, text)
  end

  def check_user_is_present(user, user_id)
    is_user_present?(user, user_id)
  end
end
