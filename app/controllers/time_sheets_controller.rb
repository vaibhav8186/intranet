require 'rest-client'

class TimeSheetsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_action :is_user_exist?, only: :create

  def create
    ret, time_sheets_data = @time_sheet.parse_timesheet_data(params) unless params['user_id'].nil?
    if ret == true
      create_time_sheet(time_sheets_data, params)
    else
      render json: { text: '' }, status: :bad_request
    end
  end

  def create_time_sheet(time_sheets_data, params)
    @time_sheet.attributes = time_sheets_data
    if @time_sheet.save
      render json: { text: "*Timesheet save successfully*" }, status: :created
    else
      if @time_sheet.errors.full_messages.present?
        text ="\`Error :: record already present for given time.\`"
        @time_sheet.post_message_to_slack(params['channel_id'], text)
      end

      render json: { text: 'fail' }, status: :unprocessable_entity
    end
  end

  private

  def is_user_exist?
    @time_sheet = TimeSheet.new
    user = User.where("public_profile.slack_handle" => params['user_id'])
    return unless user.first.nil?
    email = @time_sheet.get_user_info(params['user_id'])
    exists_user = User.where(email: email)
    if exists_user.first.nil?
      render json: { text: 'Please create your intranet account' }, status: :unauthorized
    else
      exists_user.first.public_profile.update_attribute(:slack_handle, params['user_id'])
    end
  end
end
