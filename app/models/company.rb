class Company
  include Mongoid::Document
  include Mongoid::Slug

  mount_uploader :logo, FileUploader
  
  field :name, type: String
  field :address, type: String
  field :gstno, type: String
  field :logo, type: String
  field :website, type: String

  has_many :projects, dependent: :destroy
  embeds_many :contact_persons
  accepts_nested_attributes_for :contact_persons, allow_destroy: true, reject_if: :all_blank

  slug :name


  validates_presence_of :name
  validate :website_url

  def website_url
    url = URI.parse(website) rescue false
    is_valid = url.kind_of?(URI::HTTP) || url.kind_of?(URI::HTTPS)
    errors.add(:website, "Invalid Website URL") unless is_valid
  end 

end
