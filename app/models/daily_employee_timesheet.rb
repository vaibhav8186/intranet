class DailyEmployeeTimesheet
  include Mongoid::Document
  include CalculateWorkedHours

  field :number_of_worked_hours, type: String
  field :number_of_free_hours, type: Float
  field :number_of_projects, type: Integer

  belongs_to :user

  ONE_DAY_WORKING_MINUTES = 480

  def calculate_free_hours(minutes)
    free_hours = free_minute = 0.0
    remaining_minutes = ONE_DAY_WORKING_MINUTES - minutes
    return free_hours, free_minute if remaining_minutes <= 0
    free_hours, free_minute = calculate_hours_and_minutes(remaining_minutes)
  end
end
