class Leave
  include Mongoid::Document
  belongs_to :user
  belongs_to :leave_type
  belongs_to :organization


  field :reason, type: String
  field :starts_at, type: Date
  field :ends_at, type: Date
  field :contact_address, type: String
  field :contact_number, type: Integer
  field :status, type: String
  field :reject_reason, type: String
  field :number_of_days, type: Float

  validates :reason, :starts_at, :ends_at, :contact_address, :contact_number, :leave_type_id, :presence => true
  validates :contact_number, :numericality => {:only_integer => true}
  validates :number_of_days, :numericality => true
  validate :validates_all

  def access_params(params, available_leaves)
    @leave_params = params
    @available_leaves = available_leaves
  end

  def valid_date(date)
regexp = /\d{2}\/\d{2}\/\d{4}/
date = date.to_s
    if date.include?("/")
      arr_date = date.split("/")
    elsif date.include?("-")
            arr_date = date.split("-")
    end
    if regexp.match(date) != nil
      if arr_date != nil && arr_date.length == 3
        if Date.valid_date?(arr_date[2].to_i, arr_date[1].to_i, arr_date[0].to_i)
          return true
        end
      end
    end
    return false
  end

  def validates_all
    if @available_leaves == nil
      errors[:base] << "Leaves are not assigned for you. Please contact your administrator"
    end
    leave_type = nil
    if @leave_params != nil
      if @leave_params["leave_type_id"] != nil && @leave_params["leave_type_id"] != ""
        leave_type = LeaveType.find(@leave_params["leave_type_id"])
        if number_of_days != nil
          if leave_type.can_apply != nil
            if number_of_days > leave_type.can_apply
              errors.add(:can_apply, "Number of leaves are more. You can apply for #{leave_type.can_apply}")
            end
          end
          number_days = @available_leaves[@leave_params[:leave_type_id]]
          if number_of_days > number_days.to_f
            errors.add(:number_of_days, "Leaves are more than available. Available leaves are #{@available_leaves[@leave_params["leave_type_id"]]}")
          end
        end
      end
    end
    if starts_at != ""
      if valid_date(starts_at) != true
        errors.add(:starts_at, "Invalid start date")
      elsif starts_at < Date.today
        errors.add(:starts_at, "Start date cannot be past")
      elsif starts_at > ends_at
        errors.add(:starts_at, "Start date cannot be grater than end date")
      end
    end
    if ends_at != ""
      if !valid_date(ends_at)
        errors.add(:ends_at, "Invalid end date")
      elsif ends_at < starts_at
        errors.add(:ends_at, "End date should not be before start date")
      end
    end
  end

end