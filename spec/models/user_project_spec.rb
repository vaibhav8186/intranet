require 'rails_helper'

RSpec.describe UserProject, type: :model do
  context 'validation' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project) }
    
    it 'Should success' do
      user_project = FactoryGirl.create(:user_project, user_id: user.id, project_id: project.id)
      expect(user_project).to be_present
    end
    
    it 'Should fail because user id not present' do
      user_project = FactoryGirl.build(:user_project, project_id: project.id)
      user_project.save
      expect(user_project.errors.full_messages).to eq(["User can't be blank"])
    end
    
    it 'Should fail because project id not present' do
      user_project = FactoryGirl.build(:user_project, user_id: user.id)
      user_project.save
      expect(user_project.errors.full_messages).to eq(["Project can't be blank"])
    end
    
    it 'Should fail because start date not present' do
      user_project = FactoryGirl.build(:user_project, user_id: user.id, project_id: project.id, start_date: nil)
      user_project.save
      expect(user_project.errors.full_messages).to eq(["Start date can't be blank"])
    end
  end
end
