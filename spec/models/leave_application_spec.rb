require 'spec_helper'

describe LeaveApplication do
  context 'Validation specs' do
    it { should have_fields(:start_at, :end_at, :reason, :contact_number, :reject_reason, :leave_status) }
    it { should belong_to(:user) }
    it { should validate_presence_of(:start_at) }
    it { should validate_presence_of(:end_at) }
    it { should validate_presence_of(:reason) }
    it { should validate_presence_of(:contact_number) }
    it { should validate_numericality_of(:contact_number) }
  end

  context 'Validate date - Cross date validation - ' do

    before do
      @user = FactoryGirl.create(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01))) 
    end


    it 'should not be able to apply leave for same date' do
      date = Date.today
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2, start_at: date, end_at: (date + 1.day))
      leave_application2 = FactoryGirl.build(:leave_application, user_id: @user.id, number_of_days: 1, start_at: (date + 1.day), end_at: (date + 1.day))
      expect(leave_application2.valid?).to eq(false)
      leave_application2.errors[:base].should eq(["Already applied for leave on same date"])
    end

    it 'start date should not exists in the range of applied leaves'
    it 'end date should not exists in the range of applied leaves'
    it 'no start date of any existing leave should come in the range of leave appling '
    it 'no end date of any existing leave should come in '

  end

  context 'Method specs ' do

    before do
      @user = FactoryGirl.create(:user, role: 'Employee')
      @user = FactoryGirl.create(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01))) 
    end

    it 'end date can be equal to start date' do
      date = Date.today
      leave_application = FactoryGirl.build(:leave_application, user_id: @user.id, number_of_days: 2, start_at: date, end_at: date)
      expect(leave_application.valid?).to eq(true)
    end

    it 'end date should not be less than start date' do
      date = Date.today
      leave_application = FactoryGirl.build(:leave_application, user_id: @user.id, number_of_days: 2, start_at: date, end_at: (date - 1.day))
      expect(leave_application.valid?).to eq(false)
      leave_application.errors[:end_at].should be_present
    end

    it "mail for approval shouldn't get sent if not pending" do
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2)
      Sidekiq::Extensions::DelayedMailer.jobs.clear
      leave_application.update_attributes(leave_status: 'Approved')
      Sidekiq::Extensions::DelayedMailer.jobs.size.should eq(0)
    end

    it "mail for approval should get sent if any field has been updated and if pending" do
      leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: 2)
      Sidekiq::Extensions::DelayedMailer.jobs.clear
      leave_application.update_attributes(number_of_days: 1)
      Sidekiq::Extensions::DelayedMailer.jobs.size.should eq(1)
    end

    context 'self.process_leave ' do
    
      before do
        @user = FactoryGirl.create(:user, role: 'Employee')
        @user = FactoryGirl.create(:user, private_profile: FactoryGirl.build(:private_profile, date_of_joining: Date.new(Date.today.year, 01, 01))) 
        @available_leaves = @user.employee_detail.available_leaves
        @number_of_days = 2
      end

      it 'should add leaves back if status changed from approved to rejected' do
        leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: @number_of_days)
        @user.reload
        expect(@user.employee_detail.available_leaves).to eq(@available_leaves-@number_of_days)
        @message = LeaveApplication.process_leave(leave_application.id, APPROVED, :process_accept_application, '')
        @user.reload
        expect(@user.employee_detail.available_leaves).to eq(@available_leaves-@number_of_days)

        @message.should eq({type: :notice, text: "Approved Successfully"})

        @message = LeaveApplication.process_leave(leave_application.id, REJECTED, :process_reject_application, '')
        @message.should eq({type: :notice, text: "Rejected Successfully"})
        @user.reload
        expect(@user.employee_detail.available_leaves).to eq(@available_leaves)
      end

      context 'should deduct leaves if status changed from' do
        it 'nil to pending' do
          leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: @number_of_days)
          @user.reload
          expect(@user.employee_detail.available_leaves).to eq(@available_leaves-@number_of_days)
        end

        it 'rejected to approved' do
          leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: @number_of_days)
          @user.reload
          expect(@user.employee_detail.available_leaves).to eq(@available_leaves-@number_of_days)

          @message = LeaveApplication.process_leave(leave_application.id, REJECTED, :process_reject_application, '')
          @message.should eq({type: :notice, text: "Rejected Successfully"})
          @user.reload
          expect(@user.employee_detail.available_leaves).to eq(@available_leaves)

          @message = LeaveApplication.process_leave(leave_application.id, APPROVED, :process_accept_application, '')
          @user.reload
          expect(@user.employee_detail.available_leaves).to eq(@available_leaves-@number_of_days)

          @message.should eq({type: :notice, text: "Approved Successfully"})
        end
      end

      context 'should not deduct leaves if status ' do
        
        it 'changed from pending to approved' do
          leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: @number_of_days)
          @user.reload
          available_leaves = @user.employee_detail.available_leaves

          @message = LeaveApplication.process_leave(leave_application.id, APPROVED, :process_accept_application, '')
          @user.reload
          expect(@user.employee_detail.available_leaves).to eq(available_leaves)

          @message.should eq({type: :notice, text: "Approved Successfully"})
        end

        it 'does not change' do
          leave_application = FactoryGirl.create(:leave_application, user_id: @user.id, number_of_days: @number_of_days)
          LeaveApplication.process_leave(leave_application.id, APPROVED, :process_accept_application, '')
          @user.reload
          available_leaves = @user.employee_detail.available_leaves

          @message = LeaveApplication.process_leave(leave_application.id, APPROVED, :process_accept_application, '')
          @user.reload
          expect(@user.employee_detail.available_leaves).to eq(available_leaves)

          @message.should eq({type: :error, text: "Leave is already Approved"})
        end
      end
    end

  end
end
