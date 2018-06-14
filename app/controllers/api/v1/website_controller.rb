class Api::V1::WebsiteController < ApplicationController

  before_filter :restrict_access
  caches_action :team, cache_path: "website/team"
  caches_action :portfolio, cache_path: "website/portfolio"

 def team
   render :json => User.visible_on_website.asc(:website_sequence_number).as_json(team_fields)
 end

 def portfolio
   render :json => Project.visible_on_website.sort_by_position.as_json(project_fields)
 end

 private

 def team_fields
   {only: [:email], include: { public_profile: {only: [:name, :modal_name, :github_handle, :twitter_handle, :facebook_url, :linkedin_url, 
     :blog_url], methods: [:name, :image_medium_url, :modal_name]}, employee_detail: {only: [:designation, :description, :employee_id]}}}
 end

 def project_fields
   {only: [:name, :description, :url], methods: [:case_study_url, :tags, :image_url]}
 end

 def restrict_access
   host = URI(request.referer).host if request.referer.present?
   head :unauthorized unless(host.present? && (host.match(/joshsoftware\.com/) || host.match(/josh-website-test/)))
 end
end
