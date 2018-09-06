require 'spec_helper'

describe ProjectsController do

  before(:each) do
   @admin = FactoryGirl.create(:user, role: 'Admin')
   sign_in @admin
  end

  describe "GET index" do
    it "should list all projects" do
      get :index
      should respond_with(:success)
      should render_template(:index)
    end
  end

  describe "GET new" do
    it "should respond with success" do
      get :new
      should respond_with(:success)
      should render_template(:new)
    end

    it "should create new project record" do
      get :new
      assigns(:project).new_record? == true
    end
  end

  describe "GET create" do
    it "should create new project" do
      post :create, {project: {name: "Intranet", code_climate_id: "12345", code_climate_snippet: "Intranet"}}
      flash[:success].should eql("Project created Succesfully")
      should redirect_to projects_path
    end

    it "should not save project without name" do
      project = FactoryGirl.build(:project, name: "")
      post :create, {project: {name: "", code_climate_id: "12345", code_climate_snippet: "Intranet"}}
      project.errors.full_messages.should_not equal([])
      should render_template(:new)
    end
  end

  describe 'PATCH update' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project) }

    it 'Should update manager ids and managed_project_ids' do
      user_id = []
      user_id << user.id
      patch :update, id: project.id, project: { manager_ids: user_id }
      expect(project.reload.manager_ids.include?(user.id)).to eq(true)
      expect(user.reload.managed_project_ids.include?(project.id)).to eq(true)
    end
  end

  describe "GET show" do
    it "should find one project record" do
      project = FactoryGirl.create(:project)
      get :show, id: project.id
      expect(assigns(:project)).to eq(project)
    end

    it 'Should equal to managers' do
      user = FactoryGirl.create(:user, role: 'Manager')
      project = FactoryGirl.create(:project)
      project.managers << user
      get :show, id: project.id
      expect(assigns(:managers)).to eq(project.managers)
    end
  end

  describe "GET generate_code" do
    it "should respond with json" do
      get :generate_code, {format: :json}
      response.header['Content-Type'].should include 'application/json'
    end

    it "should generate 6 digit aplphanuric code" do
      get :generate_code, {format: :json}
      parse_response = JSON.parse(response.body)
      expect(parse_response["code"].length).to be 6
    end
  end

  describe 'POST update_sequence_number' do
    it "must update project position sequence number" do
      projects = FactoryGirl.create_list(:project, 3)
      projects.init_list!
      last = projects.last
      expect(last.position).to eq(3)
      xhr :post, :update_sequence_number, id:  projects.last.id, position: 1
      expect(last.reload.position).to eq(1)
    end
  end

  describe 'DELETE team member' do
    let!(:project) { FactoryGirl.build(:project) }
    it 'Should delete manager' do
      user = FactoryGirl.build(:user, role: 'Manager')
      project.managers << user
      project.save
      user.save
      delete :remove_team_member, :format => :js, id: project.id, user_id: user.id, role: user.role
      expect(project.reload.manager_ids.include?(user.id)).to eq(false)
      expect(user.reload.managed_project_ids.include?(user.id)).to eq(false)
    end

    it 'Should delete employee' do
      user = FactoryGirl.build(:user, role: 'Employee')
      project.users << user
      project.save
      user.save
      delete :remove_team_member, :format => :js, id: project.id, user_id: user.id, role: user.role
      expect(project.reload.user_ids.include?(user.id)).to eq(false)
      expect(user.reload.managed_project_ids.include?(user.id)).to eq(false)
    end
  end
end
