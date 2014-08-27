require 'calendar_api'
require 'schedule_helper'

class SchedulesController < ApplicationController
	load_and_authorize_resource
	
  def index
    unless params[:starts_at]
      @future_events = Schedule.where(:interview_date.gt => Date.today)
      @past_events = Schedule.where(:interview_date.lt => Date.today)
      @today_events = Schedule.where(interview_date: Date.today)
      @all_events = Schedule.all
    else
      start_date = Date.strptime(params[:starts_at], "%m/%d/%Y")
      end_date = Date.strptime(params[:ends_at], "%m/%d/%Y")
      @future_events = Schedule.where(:interview_date.gt => Date.today).and(:interview_date.lte => end_date)
      @today_events = Schedule.where(interview_date: Date.today).and(:interview_date.gte => start_date ).and(:interview_date.lte => end_date)
      @past_events = Schedule.where(:interview_date.lt => Date.today).and(:interview_date.gte => start_date)
      @all_events = Schedule.where(:interview_date.gte => start_date).and(:interview_date.lte => end_date)
    end
  end

  def new
    @users = User.all
  end

  def create
    @users = User.all
    result = CalendarApi.create_event(generate_event_body)

    if result
      event_body = JSON.load(result.body)
      if result.status == 200
        @schedule.event_id = event_body['id']
        @schedule.save
        redirect_to schedules_path
      else
        flash[:error] = "Failed due to : #{event_body['error']['message']}"
        render :new
      end
    else
      flash[:error] = "Failed to create event"
      render :new
    end
  end

  def destroy
    result = CalendarApi.delete_event(@schedule.event_id)

    # remove event or already deleted event in google calendar
    if result.status == 204 || result.status == 410
      @schedule.delete
      redirect_to schedules_path
    else
      flash[:error] = "Failed due to : #{JSON.load(result.body)['error']['message']}"
      redirect_to action: 'index'
    end
  end

  def show
    result = CalendarApi.get_event(@schedule.event_id)
    
    if result.status == 200
      @event = JSON.load(result.body)
    else
      flash[:error] = "Failed due to : #{JSON.load(result.body)['error']['message']}"
      redirect_to action: 'index'
    end
  end

  def edit
    @users = User.all
  end

  def update
    @users = User.all

    if @schedule.update_attributes(schedule_params)
      result = CalendarApi.update_event(@schedule.event_id, generate_event_body)
      event_body = JSON.load(result.body)
      
      if result.status == 200
        redirect_to schedules_path
      else
        flash[:error] = "Failed due to : #{JSON.load(result.body)['error']['message']}"
        render :edit
      end
    else
      flash[:error] = "Failed to update event"
      render :edit
    end
  end

  def get_event_status
    @schedule = Schedule.find(params[:schedule_id])
    @schedule.status= (params[:status])
    @schedule.save
    redirect_to schedules_path		
  end

  def event_status
    @schedule= Schedule.find(params[:schedule_id])		
  end

  def feedback
    @schedule = Schedule.find(params[:schedule_id])
    @schedule.feedback[params["attendee_name"]] = params[:comment]	
    @schedule.save
    redirect_to schedule_path(@schedule)
  end

  private

  def schedule_params
    params.require(:schedule).permit(:summary, :description, :interview_date, :interview_time, :interview_type, :event_id, candidate_details: [:name, :email, :telephone, :skype_id], public_profile: [:git, :linkedin], interviewers: [])
  end

  def generate_event_body
    interviewers = params[:interviewers]
    datetime = ScheduleHelper.convert_into_rfc3339(@schedule)
    event = ScheduleHelper.make_event(@schedule, datetime)
    event = get_interviewers(event, interviewers)
  end

  def get_interviewers(event, interviewers)
    @schedule.users = []
    interviewers.each do |interviewer|
      if interviewer.present?
        user = User.find(interviewer)
        @schedule.users << user
        event["attendees"].push('email' => user.email)
      end
    end
    event
  end
end
