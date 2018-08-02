module CheckUser
  extend ActiveSupport::Concern

  def is_user_present?(user, user_id)
    return true unless user.nil?
    email = SlackApiService.new.get_user_info(user_id)
    existing_user = User.where(email: email) if email
    return false if existing_user.blank?
    existing_user.first.public_profile.update_attribute(:slack_handle, user_id)
    return true
  end
end