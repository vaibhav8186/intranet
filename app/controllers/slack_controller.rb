class SlackController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_action :user_exists?, only: :projects
  def projects
    projects =
      unless @user.role == 'Manager'
        @user.projects.pluck(:display_name) unless @user.nil?
      else
        @user.managed_projects.pluck(:name) unless @user.nil?
      end
    projects = @slack_bot.prepend_index(projects) unless projects.blank?
    render json: { text: 'You are not working on any project' } and return if projects.blank?
    render json: { text: projects }, status: 200
  end

  private

  def user_exists?
    load_user
    @slack_bot = SlackBot.new
    @user = @slack_bot.fetch_email_and_associate_to_user(params['user_id']) if @user.blank?
    unless @user
      render json: { text: 'You are not part of organization contact to admin' }, status: :unauthorized
    end
  end

  def load_user
    @user = User.where('public_profile.slack_handle' => params['user_id']).first unless params['user_id'].nil?
  end
end
