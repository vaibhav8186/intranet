require 'rest-client'

class TimeSheetsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    @time_sheet = TimeSheet.new
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
        text ="\`Error :: #{@time_sheet.errors.full_messages.join(', ')}\`"
        @time_sheet.post_message_to_slack(params['channel_id'], text)
      end

      render json: { text: 'fail' }, status: :unprocessable_entity
    end
  end
end
