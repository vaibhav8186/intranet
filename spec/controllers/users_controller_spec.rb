require 'spec_helper'

describe UsersController do

  context "Inviting user" do
    before(:each) do
      @admin = FactoryGirl.create(:user, role: 'Admin', email: "admin@joshsoftware.com")
      sign_in @admin
    end

    it 'In order to invite user' do
      get :invite_user
      should respond_with(:success)
      should render_template(:invite_user)
    end

    it 'should not invite user without email and role' do
      post :invite_user, {user: {email: "", role: ""}}
      should render_template(:invite_user)
    end

    it 'invitee should have joshsoftware account' do
      post :invite_user, {user: {email: "invitee@joshsoftware.com", role: "Employee"}}
      flash.notice.should eql("Invitation sent Succesfully")
      User.count.should == 2
    end

  end
  context "update" do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project, name: 'test_project') }

    before(:each) do
      @user = FactoryGirl.create(:user, role: 'Employee', email: 'sanjiv@joshsoftware.com',
              public_profile: FactoryGirl.build(:public_profile), private_profile: FactoryGirl.build(:private_profile))
      sign_in @user
    end
    it "public_profile" do
      params = {"public_profile"=>{"first_name" => "sanjiv", "last_name"=>"Jha", "gender"=>"Male", "mobile_number"=>"9595808669",
                 "blood_group"=>"A+", "date_of_birth"=>"15-10-1980", "skills"=>"", "github_handle"=>"",
                 "twitter_handle"=>"", "blog_url"=>""}, "id" => @user.id }
      put :public_profile, params

      @user.errors.full_messages.should eq([])
    end

    it "should fail in case of public profile if required field missing" do
      params = {"public_profile"=>{"last_name"=>"Jha", "gender"=>"Male", "mobile_number"=>"", "blood_group"=>"A+",
                "date_of_birth"=>"15-10-2013", "skills"=>"", "github_handle"=>"", "twitter_handle"=>"", "blog_url"=>""},
                "id"=> @user.id}

      put :public_profile, params
      @user.errors.full_messages.should_not eq(nil)
    end

    it "private profile successfully " do
      params = {"private_profile" => {"pan_number"=> @user.private_profile.pan_number, "personal_email"=>"narutosanjiv@gmail.com",
                "passport_number" =>"", "qualification"=>"BE", "date_of_joining"=> Date.new(Date.today.year, 01, 01),
                "work_experience"=>"", "previous_company"=>"", "id" => @user.private_profile.id}, "id"=> @user.id}

      put :private_profile, params
      @user.errors.full_messages.should eq([])
    end

    it "should fail if required data not sent" do
      params = {"private_profile" => {"pan_number"=> @user.private_profile.pan_number, "personal_email"=>"",
                "passport_number" =>"", "qualification"=>"BE", "date_of_joining"=>Date.new(Date.today.year, 01, 01),
                "work_experience"=>"", "previous_company"=>"", "id" => @user.private_profile.id}, "id"=> @user.id}

      put :private_profile, params
      @user.errors.full_messages.should eq([])
    end

    it 'Should add project' do
      project_ids = []
      project_ids << ""
      project_ids << project.id
      params = { user: { project_ids: project_ids } }

      patch :update, id: user.id, user: { project_ids: project_ids }
      user_project = UserProject.where(user_id: user.id, project_id: project.id).first
      expect(user_project.start_date).to eq(Date.today)
    end

    it 'Should remove project' do
      project_ids = []
      first_project = FactoryGirl.create(:project, name: 'test1')
      second_project = FactoryGirl.create(:project, name: 'test2')
      UserProject.create(user_id: user.id, project_id: first_project.id, start_date: DateTime.now - 1, end_date: nil)
      UserProject.create(user_id: user.id, project_id: second_project.id, start_date: DateTime.now - 1, end_date: nil)
      user_project = UserProject.create(user_id: user.id, project_id: project.id, start_date: DateTime.now - 1, end_date: nil)
      project_ids << ""
      project_ids << first_project.id
      project_ids << second_project.id

      patch :update, id: user.id, user: { project_ids: project_ids }
      expect(user_project.reload.end_date).to eq(Date.today)
    end

    it 'Should give an exception because project id nil' do
      project_ids = []
      first_project = FactoryGirl.create(:project, name: 'test1')
      second_project = FactoryGirl.create(:project, name: 'test2')
      project_ids << ""
      project_ids << first_project.id
      project_ids << second_project.id
      project_ids << nil
      patch :update, id: user.id, user: { project_ids: project_ids }
      expect(flash[:error]).to be_present
    end
  end
  context "get_feed" do
    before(:each) do
      @user = FactoryGirl.create(:user, role: 'Employee', email: 'sanjiv@joshsoftware.com',
              public_profile: FactoryGirl.build(:public_profile), private_profile: FactoryGirl.build(:private_profile))
      sign_in @user
    end

    it "should fetch github entries" do
      params = {"feed_type" => "github", "id" => @user.id}

      raw_response_file = File.new("spec/sample_feeds/github_example_feed.xml")
      allow(Feedjira::Feed).to receive(:fetch_raw).and_return(raw_response_file.read)

      xhr :get, :get_feed, params
      expect(assigns(:github_entries).count).to eq 4
    end

    it "should fetch blog url entries" do
      params = {"feed_type" => "blog", "id" => @user.id}
      raw_response_file = File.new("spec/sample_feeds/blog_example_feed.xml")
      allow(Feedjira::Feed).to receive(:fetch_raw).and_return(raw_response_file.read)

      xhr :get, :get_feed, params
      expect(assigns(:blog_entries).count).to eq 10
    end
  end
  context 'download excel sheet of Employee' do
    before(:each) do
      @user = FactoryGirl.create(:user, role: 'HR', email: 'vaibhav@joshsoftware.com',
              public_profile: FactoryGirl.build(:public_profile), private_profile: FactoryGirl.build(:private_profile))
      sign_in @user
    end
    let!(:userlist) { FactoryGirl.create_list(:user,status:'approved',4) }
    let!(:user) { FactoryGirl.create(:user) }
    it 'should download only status approved users' do
      params = {"status" => "approved"}
      get :index, params
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(4)
    end

    it 'should download all users' do
      params = {"status" => "all"}
      get :index, params
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(5)
    end
  end

  context 'searching and pagination' do
    before(:each) do
      @user = FactoryGirl.create(:user, role: 'Employee', email: 'vaibhav@joshsoftware.com',
              public_profile: FactoryGirl.build(:public_profile), private_profile: FactoryGirl.build(:private_profile))
      sign_in @user
    end
    let!(:userlist) { FactoryGirl.create_list(:user,5) }
    it 'should return expected users' do
      params = {"offset" => "4", "limit" => "1"}
      get :index, params
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(1)
    end
  end
end
