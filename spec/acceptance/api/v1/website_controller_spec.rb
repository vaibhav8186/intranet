require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource "Website Apis" do
  let!(:users) {FactoryGirl.create_list(:user, 3, status: 'approved', visible_on_website:  true)}
  let!(:projects) { FactoryGirl.create_list(:project, 3, visible_on_website: true)}

  get "/api/v1/team" do
    example "Get all the team members" do
      header 'Referer', 'http://joshsoftware.com'
      user = FactoryGirl.create(:user, visible_on_website: false)
      do_request
      res = JSON.parse(response_body)

      expect(status).to eq 200
      expect(res.count).to eq 3
      expect(res.last.keys).to eq ["email", "public_profile", "employee_detail"]
      expect(res.flatten).not_to include user.name

    end

    example "Must be Unauthorized for referer other than joshsoftware" do
      do_request
      expect(status).to eq 401
    end
  end

  get "/api/v1/portfolio" do
    example "Get all projects" do
      header 'Referer', 'http://joshsoftware.com'
      project = FactoryGirl.create(:project, visible_on_website: false)
      do_request
      res = JSON.parse(response_body)
      expect(status).to eq 200
      expect(res.last.keys).to eq ["description", "name", "url", "case_study_url", "tags", "image_url"]
      expect(res.count).to eq 3

    end

    example "Must be Unauthorized for referer other than joshsoftware" do
      do_request
      expect(status).to eq 401
    end
  end
end
