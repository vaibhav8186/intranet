module CheckUser
  extend ActiveSupport::Concern

  def user_present?(user, user_id)
    return true if user.present?
    email = SlackApiService.new.get_user_info(user_id)
    existing_user = User.where(email: email) if email
    return false if existing_user.blank?
    existing_user.first.public_profile.update_attribute(:slack_handle, user_id)
    return true
  end
end