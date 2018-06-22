  require 'spec_helper'

RSpec.describe CompaniesController, type: :controller do
	before(:each) do
    @admin = FactoryGirl.create(:user, role: 'Admin')
    sign_in @admin
  end

  describe "#index" do
    it "should list all companies" do
      get :index
      expect(response).to render_template(:index)
      expect(response).to have_http_status(200)
    end
  end

  describe "#new" do
    it "should respond with success" do
      get :new
      expect(response).to have_http_status(200)
      expect(response).to render_template(:new)
    end

    it "should create new project record" do
      get :new 
      assigns(:company).new_record? == true
    end
  end

  describe "#create" do 
    it "should create new project" do
      params = { company: { name: "xyz", website: "https://www.google.com", gstno: "12345"}}
      post :create, params
      expect(flash[:success]).to eq "Company created Succesfully"
    end

    it "should render new on invalid record" do 
      params = { company: { name: nil, website: "www.google.com", gstno: "12345"}}
      post :create, params
      expect(response).to render_template(:new)
    end
  end

  describe "#show" do
    it "should find company record" do
      company = FactoryGirl.create(:company)
      get :show, id: company.id
      expect(assigns(:company)).to eq(company)
    end
  end

  describe '#patch' do
    it "should update company record" do
      company = FactoryGirl.create(:company)
      patch :update, {company: { name: "google"}, id: company.id }
      expect(company.reload.name).to eq("google")
    end

    it "should accept nested attributes for contact" do 
      company = FactoryGirl.create(:company)
      params = { "company"=> { "contact_persons_attributes"=> {"0"=> {"email"=>"ajinath@joshsoftware.com",
        "name"=>"Ajinath JEdhe", "mobileno"=>"1212121212",}}}, id: company.id} 
      patch :update, params
      expect(company.reload.contact_persons.count).to eq(1)
    end 
  end

  describe '#delete' do 
    it 'should delete company record' do
      company =  FactoryGirl.create(:company)
      delete :destroy, id: company.id
      expect(Company.count).to eq(0)
      expect(response).to redirect_to(companies_path)
    end
  end
end
