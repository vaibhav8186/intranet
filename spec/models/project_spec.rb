require 'spec_helper'

describe Project do
  it {should validate_presence_of(:name)}
  it {should accept_nested_attributes_for(:users)}

  it 'must return all the tags' do
    project = FactoryGirl.create(:project, rails_version: "4.2.1", ruby_version: '2.2.3',
                                   database: "Mongodb", other_details: "Retrofit,GCM")
    expect(project.tags).to eq(["Ruby 2.2.3", "Rails 4.2.1", "Mongodb ", "Retrofit", "GCM"])
  end


  it "should use existing product code of company" do
    company = FactoryGirl.create(:company)
    project = FactoryGirl.create(:project)
    new_project = FactoryGirl.build(:project, name: "test", code: project.code)
    expect(new_project).to be_valid
  end

  it "should not use existing product code of other company" do
    company = FactoryGirl.create(:company)
    project = FactoryGirl.create(:project, company: company)
    new_project = FactoryGirl.build(:project, code: project.code)
    expect(new_project).to be_invalid
  end

  context 'validation - display name' do
    let!(:project) { FactoryGirl.create(:project) }

    it 'Should success' do
      expect(project.display_name).to eq('The_pediatric_network')
      expect(project.errors.count).to eq(0)
    end

    it 'should fail beacause display name contain white space' do
      project.display_name = 'The pediatric network'
      project.save

      expect(project.errors.full_messages).to eq(["Display name Name should not contain white space"])
      expect(project.errors.count).to eq(1)
    end

    it 'should update display name when project name is change' do
      project.name = 'Deal signal'
      project.display_name = ''
      project.save

      expect(project.display_name).to eq("Deal_signal")
      expect(project.errors.count).to eq(0)
    end

    it 'Should not trigger validation because display name is correct' do
      project.display_name = 'tpn'

      expect(project.errors.count).to eq(0)
    end
  end

end
