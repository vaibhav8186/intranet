class LeaveApplicationsController < ApplicationController
   
  before_action :authenticate_user!
  load_and_authorize_resource except: [:create, :view_leave_status, :process_leave]
  before_action :authorization_for_admin, only: [:process_leave]
 
  def new
    @leave_application = LeaveApplication.new(user_id: current_user.id)
    @available_leaves = current_user.employee_detail.try(:available_leaves)
  end
  
  def index
    @users = User.employees.not_in(role: ["Admin", "SuperAdmin"])
  end  
  
  def create
    @leave_application = LeaveApplication.new(strong_params)
    if @leave_application.save
      flash[:error] = "Leave applied successfully. Please wait for leave to be approved!!!"
    else
      @available_leaves = current_user.employee_detail.try(:available_leaves)
      flash[:error] = @leave_application.errors.full_messages.join("\n")
      render 'new' and return
    end
    #redirect_to public_profile_user_path(current_user) and return 
    redirect_to view_leaves_path(current_user) and return 
  end 

  def edit
    @available_leaves = @leave_application.user.employee_detail.available_leaves
  end

  def update
    if @leave_application.update_attributes(strong_params)
      flash[:error] = "Leave has been updated successfully. Please wait for leave to be approved!!!"
    else
      @available_leaves = current_user.employee_detail.available_leaves
      flash[:error] = @leave_application.errors.full_messages.join("\n")
      render 'edit' and return
    end 
    redirect_to ((can? :manage, LeaveApplication) ? leave_applications_path : view_leaves_path) and return 
  end

  def view_leave_status
    if ["Admin", "HR", "Manager"].include? current_user.role
      @pending_leaves = LeaveApplication.order_by(:created_at.desc).pending
      @processed_leaves = LeaveApplication.order_by(:created_at.desc).processed 
    else
      @pending_leaves = current_user.leave_applications.order_by(:created_at.desc).pending
      @processed_leaves = current_user.leave_applications.order_by(:created_at.desc).processed
    end
  end

  def strong_params
    safe_params = [
                   :user_id, :start_at, 
                   :end_at, :contact_number, :number_of_days,
                   :reason, :reject_reason, :leave_status
                  ]
    params.require(:leave_application).permit(*safe_params) 
  end

=begin Commented on 26th may 2015. Added common method process_leave
  def cancel_leave
    reject_reason = params[:reject_reason] || ''
    process_leave(params[:id], 'Rejected', :process_reject_application, reject_reason)
  end

  def approve_leave
    process_leave(params[:id], 'Approved', :process_accept_application)
  end 
=end

  def process_leave
    @leave_action = params[:leave_action]
    if params[:leave_action] == 'approve'
      @status = APPROVED
      call_function = :process_accept_application
    else
      @status = REJECTED
      call_function = :process_reject_application
    end

    @message = LeaveApplication.process_leave(params[:id], @status, call_function, params[:reject_reason])
    @leave_application = LeaveApplication.find(params[:id])
    @pending_leaves = LeaveApplication.order_by(:created_at.desc).pending
    

    respond_to do|format|
      format.js{}
      format.html{ redirect_to view_leaves_path}
    end
  end

  private

  def authorization_for_admin
    if !current_user.role?("Admin")
      flash[:error] = 'Unauthorize access'
      redirect_to root_path
    else
      return true
    end
  end 
end
