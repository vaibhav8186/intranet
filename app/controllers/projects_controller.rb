class ProjectsController < ApplicationController

  load_and_authorize_resource
  skip_load_and_authorize_resource :only => :create
  before_action :authenticate_user!
  before_action :load_project, except: [:index, :new, :create, :remove_team_member, :add_team_member]

  include RestfulAction

  def index
    @projects = Project.sort_by_position
    @projects.init_list!
    respond_to do |format|
      format.html
      format.csv { send_data @projects.to_csv }
    end
  end

  def new
    @company = Company.find(params[:company_id]) if params[:company_id]
    @project = Project.new(company: @company)
  end

  def create
    @project = Project.new(safe_params)
    if @project.save
      flash[:success] = "Project created Succesfully"
      redirect_to projects_path
    else
      render 'new'
    end
  end

  def update
    @project.user_ids = [] if params[:user_ids].blank? and params['tech_details'].nil?
    update_obj(@project, safe_params, projects_path)
  end

  def show
    @users = @project.users
  end

  def destroy
    if @project.destroy
     flash[:notice] = "Project deleted Succesfully"
    else
     flash[:notice] = "Error in deleting project"
    end
     redirect_to projects_path
  end

  def update_sequence_number
    @project.move(to: params[:position].to_i)
    render nothing: true
  end

  def remove_team_member
    team_member = @project.users.find(params[:user_id])
    @project.user_ids.delete(team_member.id)
    @project.save
    @users = @project.reload.users
  end

  def add_team_member
    @project.user_ids = params[:project][:user_ids]
    @project.save
    @users = @project.reload.users
  end

  private
  def safe_params
    params.require(:project).permit(:name, :start_date, :end_date, :managed_by, :code_climate_id, :code_climate_snippet,
    :code_climate_coverage_snippet, :is_active, :ruby_version, :rails_version, :database, :database_version, :deployment_server,
    :deployment_script, :web_server, :app_server, :payment_gateway, :image_store, :index_server, :background_jobs, :sms_gateway,
    :other_frameworks,:other_details, :image, :url, :description, :case_study,:logo, :visible_on_website, :website_sequence_number,
    :code, :number_of_employees, :invoice_date, :company_id,
    :user_ids => [])
  end

  def load_project
    @project = Project.find(params[:id])
  end
end
