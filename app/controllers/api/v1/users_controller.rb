class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!
  skip_before_filter :verify_authenticity_token

  def info
    id = current_user.present? ? current_user.id.to_s : nil
    render json: { id: id}
  end
end
