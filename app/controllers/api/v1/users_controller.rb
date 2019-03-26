class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!
  skip_before_filter :verify_authenticity_token

  def info
    render json: {} and return if current_user.blank?
    render json: { id: current_user.id.to_s, email: current_user.email, name: current_user.name}
  end
end
