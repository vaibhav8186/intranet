class SlackController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_action :is_user_present?, only: :projects
  def projects
    projects = @user.projects.pluck(:display_name) unless @user.nil?
    @slack_bot.show_projects(projects, params['channel_id']) unless projects.blank?
    render json: { text: 'You are not working on any project' } and return if projects.blank?
    render json: { text: '' }, status: 200
  end

  private

  def is_user_present?
    load_user
    @slack_bot = SlackBot.new
    return_value = @slack_bot.check_user_is_present(@user, params['user_id'])
    unless return_value
      render json: { text: 'You are not part of organization contact to admin' }, status: :unauthorized
    end
  end

  def load_user
    @user = User.where('public_profile.slack_handle' => params['user_id']).first unless params['user_id'].nil?
  end
end
