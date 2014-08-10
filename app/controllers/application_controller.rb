class ApplicationController < ActionController::Base
  helper_method :current_user
  helper_method :user_signed_in?
  helper_method :correct_user?

  protect_from_forgery with: :exception

  before_filter :store_location
  before_filter :check_for_light

  def store_location
    session[:previous_url] = request.fullpath if !INVALID_REDIRECTIONS.include?(request.fullpath) && !request.xhr? # don't store ajax calls
  end

  def after_sign_in_path_for(resource)
    session[:previous_url] || root_path
  end

  def check_for_light
    if request.url.include?('newsletter') and !current_user.try(:role).in?(['Admin', 'HR', 'Super Admin'])
      flash[:error] = 'You are not authorized to access this page.'
      redirect_to main_app.root_url and return 
    end
  end

rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_url, :alert => exception.message
  end
end
