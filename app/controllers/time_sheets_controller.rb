class TimeSheetsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_action :is_user_present?, only: :create

  def create
    return_value, time_sheets_data = @time_sheet.parse_timesheet_data(params) unless params['user_id'].nil?
    if return_value == true
      create_time_sheet(time_sheets_data, params)
    else
      render json: { text: '' }, status: :bad_request
    end
  end

  def create_time_sheet(time_sheets_data, params)
    @time_sheet.attributes = time_sheets_data
    if @time_sheet.save
      render json: { text: "*Timesheet saved successfully!*" }, status: :created
    else
      if @time_sheet.errors.messages[:from_time].present? || @time_sheet.errors.messages[:to_time].present?
        text ="\`Error :: record already present for given time.\`"
        SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      end
      render json: { text: 'fail' }, status: :unprocessable_entity
    end
  end

  private

  def is_user_present?
    load_user
    @time_sheet = TimeSheet.new
    return_value = @time_sheet.check_user_is_present(@user, params['user_id'])
    unless return_value
      render json: { text: 'You are not part of organization contact to admin' }, status: :unauthorized
    end
  end

  def load_user
    @user = User.where('public_profile.slack_handle' => params['user_id']).first unless params['user_id'].nil?
  end
end
