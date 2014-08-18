class HomeController < ApplicationController
  
  def index
    @projects = Project.all_active
    @bonusly_updates = get_bonusly_updates
    render stream: true
  end

  private

  def get_bonusly_updates
    bonus = Api::Bonusly.new(BONUSLY_TOKEN)
    bonus.bonusly_messages
  end
end
