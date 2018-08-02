class Career
  include Mongoid::Document

  mount_uploader :resume, FileUploader
  mount_uploader :cover, FileUploader

  field :first_name,           :type => String
  field :last_name,            :type => String
  field :email,                :type => String
  field :contact_number,       :type => String
  field :current_company,      :type => String
  field :current_ctc,          :type => String
  field :linkedin_profile,     :type => String
  field :github_profile,       :type => String
  field :resume
  field :portfolio_link,       :type => String
  field :cover

  validates_presence_of :first_name
  validates_presence_of :last_name
  validates :email, format: { with: EMAIL_ADDRESS, message: 'Invalid email' }
  validates_presence_of :contact_number
  validates_presence_of :current_ctc
  validates_presence_of :linkedin_profile
  validates_presence_of :resume
  validates_presence_of :cover
end
