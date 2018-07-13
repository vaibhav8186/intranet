class SlackController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def projects
    user = User.where('public_profile.slack_handle' => params['user_id']).first unless params['user_id'].nil?
    projects = user.projects.pluck(:name) unless user.nil?
    @slack = SlackBot.new
    @slack.show_projects(projects, params['channel_id']) unless projects.nil?
    unless user.nil?
      render json: { text: '' }, status: 200
    else
      render json: { text: 'You are not register as slack user' }, status: 401
    end
  end
end
