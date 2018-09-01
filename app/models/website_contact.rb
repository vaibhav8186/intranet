class WebsiteContact
  include Mongoid::Document

  field :name,       :type => String
  field :email,      :type => String
  field :skype_id,   :type => String
  field :phone,      :type => String
  field :message,    :type => String
  field :organization
  field :role
  field :job_title

  validates_presence_of :name
  validates :email, format: { with: EMAIL_ADDRESS, message: 'Invalid email'}

  CONTACT_US_JOB_SEEKER = 'Job Seeker'

  after_create do
    WebsiteMailer.delay.contact_us(self)
  end
end
