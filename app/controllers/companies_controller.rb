class CompaniesController < ApplicationController
  include RestfulAction

  before_action :authenticate_user!
  before_action :set_company, only: [:edit, :show, :update, :destroy]

  def index
    @companies = Company.all
    respond_to do |format|
      format.html
      format.csv { send_data @companies.to_csv }
    end
  end

  def new
  	@company = Company.new
  end

  def create
  	@company = Company.new(company_params)
  	if @company.save 
      flash[:success] = "Company created Succesfully"
      redirect_to companies_path
    else
      render 'new'
    end
  end

  def show
    @projects = @company.projects.where(is_active: true)
  end

  def update
    if @company.update(company_params)
      flash[:success] = "Company updated Succesfully" 
      redirect_to companies_path
    else
      flash[:error] = "Company: #{@company.errors.full_messages.join(',')}" 
      render 'edit'
    end
  end

  def destroy
    if @company.destroy
     flash[:notice] = "Company deleted Succesfully" 
    else
     flash[:notice] = "Error in deleting Company"
    end
    redirect_to companies_path
  end

  private
  
  def company_params
  	params.require(:company).permit(:name, :address, :gstno, :logo, :website, 
      contact_persons_attributes: [:id, :role, :name, :phone_no, :email, :_destroy]) 
  end
  
  def set_company
  	@company = Company.find(params[:id])
  end
end
