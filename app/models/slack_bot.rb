require 'rest-client'

class SlackBot < SlackRubyBot::Bot
  include Mongoid::Document

  def show_projects(projects, channel)
    params = {
      token: SLACK_API_TOKEN,
      channel: channel,
      text: "#{projects.each_with_index.map{|project, index| project.prepend("#{index+1}. ")}.join("\n")}"
    }

    resp = RestClient.post("https://slack.com/api/chat.postMessage", params)
  end

end
