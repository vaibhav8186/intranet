class Schedule
  include Mongoid::Document

  field :interview_date,           :type => Date
  field :interview_time,           :type => Time
  field :interview_type,           :type => String
  field :candidate_details,        :type => Hash
  field :public_profile,           :type => Hash
  field :summary, 								 :type => String
  field :description, 						 :type => String
  field :status,                   :type => String
  field :event_id,                 :type => String
  field :feedback,                 :type => Hash, :default=>{}
  field :sequence,                 :type => Integer, :default => 0

  mount_uploader :file, FileUploader
  has_and_belongs_to_many :users
  accepts_nested_attributes_for :users
  
  before_update :increment_sequence

  private

  # increment sequence after every update, needed while updating event in google calendar
  def increment_sequence
    self.sequence += 1
  end
end
