require 'rails_helper'
require 'spec_helper'
require 'time'
require 'date'

RSpec.describe Schedule, :type => :model do

  context "check time format" do
    it "should have correct time format" do
      schedule = FactoryGirl.create(:schedule)
      schedule.interview_time.class.should eq(ActiveSupport::TimeWithZone)
    end

    it "should not have incorrect time format" do
      schedule = FactoryGirl.create(:schedule,{interview_time: "59/23/11"}) 
      schedule.interview_time.should_not match(/(([0-1][0-9])|(2[0-3])){1}(:([0-5][0-9])){2}/)
    end
  end

  context "check date" do
    it "should have future date" do
      schedule = FactoryGirl.create(:schedule, interview_date: Date.tomorrow)
      (schedule.interview_date < Date.today).should eq(false)
    end

    it "should not have past date" do
      schedule = FactoryGirl.build(:schedule,{interview_date: "12/2/1992"})
      (schedule.interview_date < Date.today).should_not eq(false)
    end
  end

  describe "interview type" do
    
    context "interview type telephonic" do
      it "should have valid telephone no" do
        schedule = FactoryGirl.build(:schedule)
        schedule.candidate_details[:telephone].should match(/^([0-9]{10})$/)
      end

      it "should not have invalid telephone no" do
        schedule = FactoryGirl.build(:schedule, :candidate_details =>  {'telephone'=>3433})
        schedule.candidate_details['telephone'].should_not match(/^([0-9]{10})$/)  
      end
    end

    context "interview type skype" do
      it "should have valid skype id" do
        schedule = FactoryGirl.create(:schedule)
        schedule.candidate_details[:skype].should match(/^(\w{6,20})$/) 
      end

      it "should not have invalid skype id" do
        schedule = FactoryGirl.build(:schedule, :candidate_details =>  {'skype'=>"avi@@nash11"})
        schedule.candidate_details['skype'].should_not match(/^(\w{6,20})$/)
      end
    end 

    context "interview type face to face" do
      it "should have valid phone no or email id" do
        schedule = FactoryGirl.build(:schedule, :candidate_details =>  {'email'=>"abc@gmail.com",'telephone'=>"8989898989"})
        (schedule.candidate_details['telephone'].should match(/^([0-9]{10})$/) or schedule.candidate_details['email'].should match(/^([a-z0-9][\w_+]*)*[a-z0-9]@(\w+\.)+\w+$/i) ).should eq(true)

      end
    end

  end

  describe "check allowable public profiles" do
    context "profile should be github profile" do
      it "should have valid github profile" do
        schedule = FactoryGirl.create(:schedule)
        schedule.public_profile[:git].should match(/^http:\/\/github.com\/\w*$/)
      end

      it "should not have invlaid github profile" do
        schedule = FactoryGirl.build(:schedule, :public_profile => {'git'=>"http://github.in/78%"})
        schedule.public_profile['git'].should_not match(/^http:\/\/github.com\/\w*$/)
      end
    end

    context "profile should be linkedin profile" do
      it "should have valid linkedin profile" do
        schedule = FactoryGirl.create(:schedule)
        schedule.public_profile[:linkedin].should match(/^http:\/\/in.linkedin.com\/pub\/(\w|[-\/])*$/)
      end

      it "should not have invalid linkedin profile" do
        schedule = FactoryGirl.build(:schedule, :public_profile => {'linkedin'=>"http://in.linkedin.com/ad$"})
        schedule.public_profile['linkedin'].should_not match(/^http:\/\/in.linkedin.com\/pub\/(\w|[-\/])*$/)
      end
    end
  end

  describe "document valiadtion" do
    context "pdf document" do
      it "should have document type .pdf" do
        schedule = FactoryGirl.create(:schedule)
        schedule.file.file.extension.downcase.should eq('pdf')
      end

      it "should not have other format" do
        schedule = FactoryGirl.create(:schedule,file: fixture_file_upload('spec/fixtures/files/sample1.doc'))
        schedule.file.file.extension.downcase.should_not eq('pdf')
      end
    end

    context "microsoft document" do
      it "should have document type .doc,.docx" do
        schedule = FactoryGirl.create(:schedule,file: fixture_file_upload('spec/fixtures/files/sample1.doc'))
        (['doc','docx'].include?(schedule.file.file.extension.downcase)).should eq(true)
      end

      it "should not have other format" do
        schedule = FactoryGirl.create(:schedule)
        (['doc','docx'].include?(schedule.file.file.extension.downcase)).should_not eq(true)
      end
    end
  end

  context "valid interviewer" do
    it "should have registered email" do
      schedule = FactoryGirl.create(:schedule)
      email = schedule.users.first.email
      User.where(email:email).last.valid?.should eq(true)
    end

    it "should not have non registered email" do
      user = FactoryGirl.build(:user)
      schedule = FactoryGirl.build(:schedule,:users=>[user])
      email = schedule.users.first.email
      p "pppppp"
      p email
      p "pppppp"
      User.where(email:email).last.should eq(nil)
    end
  end


  #pending "add some examples to (or delete) #{__FILE__}"
end
