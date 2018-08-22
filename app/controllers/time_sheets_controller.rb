class TimeSheetsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_action :user_exists?, only: [:create, :daily_status]

  def create
    return_value, time_sheets_data = @time_sheet.parse_timesheet_data(params) unless params['user_id'].nil?
    if return_value == true
      create_time_sheet(time_sheets_data, params)
    else
      render json: { text: '' }, status: :bad_request
    end
  end

  def index
    if params[:from_date] && params[:to_date] && (params[:from_date].to_date <= params[:to_date].to_date)
      @timesheet_obj = TimeSheet.new
      timesheets = load_timesheet
      @timesheet_report = @timesheet_obj.generete_employee_timesheet_report(timesheets, params) if timesheets.present?
    end
  end

  def create_time_sheet(time_sheets_data, params)
    @time_sheet.attributes = time_sheets_data
    if @time_sheet.save
      render json: { text: "*Timesheet saved successfully!*" }, status: :created
    else
      if @time_sheet.errors.messages[:from_time].present? || @time_sheet.errors.messages[:to_time].present?
        text ="\`Error :: Record already present for given time.\`"
        SlackApiService.new.post_message_to_slack(params['channel_id'], text)
      end
      render json: { text: 'Fail' }, status: :unprocessable_entity
    end
  end

  def daily_status
    @time_sheet = TimeSheet.new
    time_sheet_log = @time_sheet.parse_daily_status_command(params)
    if time_sheet_log
      render json: { text: time_sheet_log }, status: :ok
    else
      render json: { text: 'Fail' }, status: :unprocessable_entity
    end
  end

  private

  def user_exists?
    load_user
    @time_sheet = TimeSheet.new
    @user = @time_sheet.fetch_email_and_associate_to_user(params['user_id']) if @user.blank?
    unless @user
      render json: { text: 'You are not part of organization contact to admin' }, status: :unauthorized
    end
  end

  def load_user
    @user = User.where('public_profile.slack_handle' => params['user_id']).first unless params['user_id'].nil?
  end

  def load_timesheet
    TimeSheet.collection.aggregate(
      [
        {
          "$match" => {
            "date" => {
              "$gte" => params[:from_date].to_date,
              "$lte" => params[:to_date].to_date
            }
          }
        },
        {
          "$group" => {
            "_id" => {
              "user_id" => "$user_id",
              "project_id" => "$project_id"
            },
            "totalSum" => {
              "$sum" => {
                "$subtract" => [
                  "$to_time",
                  "$from_time"
                ]
              }
            }
          }
        },
        {
          "$group" => {
            "_id" => "$_id.user_id",
            "working_status" => {
              "$push" => {
                "project_id" => "$_id.project_id",
                "total_time" => "$totalSum"
              }
            }
          }
        }
      ]
    )
  end
end
