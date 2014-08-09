require 'spec_helper'

RSpec.describe SchedulesController, :type => :controller do
  context "GET index" do
    user= FactoryGirl.create(:hr)
    
    it "lists all events" do
      @request.env["devise.mapping"] = :hr
      sign_in FactoryGirl.create(:hr)
      get :index 
      expect(response).to render_template("index")
    end
  end

  context "GET edit" do
    user= FactoryGirl.create(:hr)
    
    it "shows details of event" do
    	e1= FactoryGirl.create(:schedule)
      @request.env["devise.mapping"] = :hr
      sign_in FactoryGirl.create(:hr)
      get :edit, {id: e1.id}
      expect(response).to render_template("edit")
    end
  end

  context "GET new" do
    user= FactoryGirl.create(:hr)
    
    it "shows details of event" do
      @request.env["devise.mapping"] = :hr
      sign_in FactoryGirl.create(:hr)
      get :new
      expect(response).to render_template("new")
    end
  end

  context "GET delete" do
  user= FactoryGirl.create(:user)

    it "deletes event" do
      e1= FactoryGirl.create(:schedule)
      @request.env["devise.mapping"] = :user
      sign_in FactoryGirl.create(:user)
      get :destroy, {id: e1.id}
      expect(response).not_to redirect_to schedules_path
    end
  end
end

