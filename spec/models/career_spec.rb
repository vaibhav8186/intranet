require 'rails_helper'

RSpec.describe Career, type: :model do
  context 'validation' do
    let(:career) { FactoryGirl.build(:career) }

    it 'Should fail because first name is not present' do
      career.first_name = ' '
      expect(career).to be_invalid
      expect(career.errors.full_messages).to eq(["First name can't be blank"])
    end

    it 'Should fail because last name is not present' do
      career.last_name = ' '
      expect(career).to be_invalid
      expect(career.errors.full_messages).to eq(["Last name can't be blank"])
    end

    it 'Should fail because invalid email' do
      career.email = 'abcgmail.com'
      expect(career).to be_invalid
      expect(career.errors.full_messages).to eq(["Email Invalid email"])
    end

    it 'Should fail because contact_number is not present' do
      career.contact_number = ' '
      expect(career).to be_invalid
      expect(career.errors.full_messages).to eq(["Contact number can't be blank"])
    end

    it 'Should fail because current_ctc is not present' do
      career.current_ctc = ' '
      expect(career).to be_invalid
      expect(career.errors.full_messages).to eq(["Current ctc can't be blank"])
    end

    it 'Should fail because linkedin profile is not present' do
      career.linkedin_profile = ' '
      expect(career).to be_invalid
      expect(career.errors.full_messages).to eq(["Linkedin profile can't be blank"])
    end

    it 'Should fail because resume is not uploaded' do
      career.resume = ' '
      expect(career).to be_invalid
      expect(career.errors.full_messages).to eq(["Resume You are not allowed to upload nil files, allowed types: pdf, jpg, jpeg, gif, png, doc, xls, xlsx"])
    end

    it 'Should not allowd to upload .txt file' do
      career.resume = fixture_file_upload("/home/josh/a.txt")
      expect(career).to be_invalid
      expect(career.errors.full_messages).to eq(["Resume You are not allowed to upload \"txt\" files, allowed types: pdf, jpg, jpeg, gif, png, doc, xls, xlsx"])
    end

    it 'Should fail because cover is not uploaded' do
      career.cover = ' '
      expect(career).to be_invalid
      expect(career.errors.full_messages).to eq(["Cover You are not allowed to upload nil files, allowed types: pdf, jpg, jpeg, gif, png, doc, xls, xlsx"])
    end
  end
end
