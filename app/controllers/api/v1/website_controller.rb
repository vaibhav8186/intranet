class Api::V1::WebsiteController < ApplicationController

  before_filter :restrict_access

 def team
   render :json => User.visible_on_website.sort_by {|u| u.employee_detail.employee_id.to_i }.as_json(team_fields)
 end

 private

 def team_fields
   { only: [:email], include: { public_profile: {only: [:name, :image_url,:modal_name, :github_handle, :twitter_handle, :facebook_url, :linkedin_url, :image], methods: [:name, :image_url, :modal_name]}, employee_detail: {only: [:designation, :description, :employee_id]}}}
 end

 def restrict_access

   host = URI(request.referer).host if request.referer.present?
   head :unauthorized unless host.present? && host.match(/joshsoftware\.com/)
 end
end
