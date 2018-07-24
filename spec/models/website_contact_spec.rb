require 'rails_helper'

RSpec.describe WebsiteContact, type: :model do
  context 'Validation' do
    let!(:website_contact) { FactoryGirl.build(:website_contact) }

    it 'Should success' do
      expect(website_contact).to be_valid
      expect(website_contact.errors.count).to eq(0)
    end

    context 'Failure' do
      it 'Should fail because name is not present' do
        website_contact.name = ''
        expect(website_contact).to be_invalid
        expect(website_contact.errors.full_messages).to eq(["Name can't be blank"])
      end

      it 'Should fail because email is not present' do
        website_contact.email = ''
        expect(website_contact).to be_invalid
        expect(website_contact.errors.full_messages).to eq(["Email Invalid email"])
      end
    end
  end
end
