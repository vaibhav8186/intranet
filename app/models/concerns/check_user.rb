module CheckUser
  extend ActiveSupport::Concern

  def call_slack_api_service_and_fetch_email(user_id)
    email = SlackApiService.new.get_user_info(user_id)
    existing_user = User.where(email: email) if email
    return false if existing_user.blank?
    return_value = existing_user.first.public_profile.update_attribute(:slack_handle, user_id)
    return_value ? existing_user.first : false
  end
end