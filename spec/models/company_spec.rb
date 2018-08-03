require 'spec_helper'

RSpec.describe Company, type: :model do
  it { should have_fields(:name, :gstno, :logo, :website) }
  it { should embed_many :contact_persons }
  it { should have_many :addresses }
  it { should accept_nested_attributes_for :contact_persons }
  it { should accept_nested_attributes_for :addresses }
  it { should have_many(:projects) }
  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name)}

  it "Should validate website URL" do
    company = FactoryGirl.build(:company)
    company.website = "invalid.website"
    expect(company.valid?).to be_falsy
  end

  it "should create contact_persons" do
    company = FactoryGirl.create(:company)
    company.contact_persons.create(role: "Accountant", email: "xyz@test.com")
    expect(company.contact_persons.count).to eq(1)
  end

  it "should create addresses" do
    company = FactoryGirl.create(:company)
    company.addresses.create(city: "Pune", state: "MH", landline_no: "96XXXXXX")
    expect(company.addresses.count).to eq(1)
  end
end
