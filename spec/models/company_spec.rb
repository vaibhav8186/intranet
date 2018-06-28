require 'spec_helper'

RSpec.describe Company, type: :model do
  it { should have_fields(:name, :address, :gstno, :logo, :website) }
  it { should embed_many :contact_persons }
  it { should have_many :addresses }
  it { should accept_nested_attributes_for :contact_persons }
  it { should accept_nested_attributes_for :addresses }
  it { should have_many(:projects) }

  it "Should validate website URL" do
    company = FactoryGirl.build(:company)
    company.website = "invalid.website"
    expect(company.valid?).to be_falsy
  end

  it "should return contact_persons" do
    company = FactoryGirl.create(:company)
    FactoryGirl.create(:company)
    company.contact_persons.create(role: "Accountant", email: "xyz@test.com")
    expect(company.contact_persons.count).to eq(1)
  end
end
