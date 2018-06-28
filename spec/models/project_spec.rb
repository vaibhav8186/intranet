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
end
