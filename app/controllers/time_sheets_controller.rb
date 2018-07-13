require 'rest-client'

class TimeSheetsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  
  def create
    time_sheets_text = params['text']
    @time_sheet = TimeSheet.new
    ret = @time_sheet.parse_string(time_sheets_text, params)
    if ret == true
      render json: { text: 'Ok' }, status: 200
    else
      render json: { text: 'fail' }, status: 400
    end
  end
end
