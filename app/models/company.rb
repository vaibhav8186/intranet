class Company
  include Mongoid::Document
  include Mongoid::Slug

  mount_uploader :logo, FileUploader

  field :name, type: String
  field :gstno, type: String
  field :logo, type: String
  field :website, type: String

  has_many :projects, dependent: :destroy
  embeds_many :contact_persons
  has_many :addresses, dependent: :destroy

  accepts_nested_attributes_for :addresses, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :contact_persons, allow_destroy: true, reject_if: :all_blank

  slug :name

  validates :name, uniqueness: true, presence: true
  validate :website_url

  def website_url
    return true if website.nil? || website.empty?
    url = URI.parse(website) rescue false
    is_valid = url.kind_of?(URI::HTTP) || url.kind_of?(URI::HTTPS)
    errors.add(:website, "Invalid Website URL") unless is_valid
  end

  def project_codes
    projects.as_json(only: [:name,:code])
  end
end
