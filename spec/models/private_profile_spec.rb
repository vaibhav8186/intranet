require 'spec_helper'

describe PrivateProfile do
  
  it { should have_fields(:pan_number, :personal_email, :passport_number, :qualification, :date_of_joining, :work_experience, :previous_company) }
  it { should have_field(:date_of_joining).of_type(Date) }
  it { should have_many :addresses }
  it { should embed_many :contact_persons }
  it { should be_embedded_in(:user) }
  it { should accept_nested_attributes_for(:addresses) }
  it { should accept_nested_attributes_for(:contact_persons) }
=begin
  it { should validate_presence_of(:qualification).on(:update) }
  it { should validate_presence_of(:date_of_joining).on(:update) }
  it { should validate_presence_of(:personal_email).on(:update) }
=end

  context 'Validate Date of joining' do
    it 'should not update user beacuse joining date is not present' do
      user = FactoryGirl.create(:user)
      user.status = 'approved'
      private_profile = user.private_profile
      private_profile.date_of_joining = ''

      expect(user.save).to eq(false)
      expect(user.generate_errors_message).to eq("Private profile is invalid  Date of joining can't be blank")
    end

    context 'validation' do
      let!(:user){ FactoryGirl.create(:user) }

      after do
        expect(user.save).to eq(true)
        expect(user.valid?).to eq(true)
      end

      it 'validation should not trigger because role is not employee' do
        user.role = 'Intern'
        byebug
        expect(user.role).to_not be('Employee')
      end

      it 'validayion should not trigger because role is not HR' do
        user.role = 'Intern'
        expect(user.role).to_not be('HR')
      end
    end

    it 'Validation should not trigger on create' do
      user = FactoryGirl.create(:user)

      expect(user.valid?).to eq(true)
    end

    it 'should update user because joing date is present' do
      user = FactoryGirl.create(:user)

      expect(user.save).to eq(true)
      expect(user.generate_errors_message).to eq('  ')
    end
  end
end
  
