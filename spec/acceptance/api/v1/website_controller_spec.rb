require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource "Team Api" do


  let!(:users) {FactoryGirl.create_list(:user, 3, status: 'approved', visible_on_website:  true)}

  get "/api/v1/team" do
    example "Get all the team members" do
      header 'Referer', 'http://joshsoftware.com'
      user = FactoryGirl.create(:user)
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
end
