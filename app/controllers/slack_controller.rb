class SlackController < ApplicationController
	skip_before_filter :verify_authenticity_token

	def get_projects
		user = User.where('public_profile.slack_handle' => params['user_id']).first
		projects = user.projects.pluck(:name) unless user.nil?
		@slack = SlackBot.new
		@slack.show_projects(projects, params['channel_id']) unless projects.nil?
		render json: { text: '' }, status: 200
	end
end
