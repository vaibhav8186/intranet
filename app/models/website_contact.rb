class WebsiteContact
  include Mongoid::Document

  field :name,       :type => String
  field :email,      :type => String
  field :skype_id,   :type => String
  field :phone,      :type => String
  field :message,    :type => String

  validates_presence_of :name
  validates :email, format: { with: EMAIL_ADDRESS, message: 'Invalid email'}
end
