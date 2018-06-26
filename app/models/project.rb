class Project
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps
  include ActsAsList::Mongoid

  mount_uploader :image, FileUploader
  mount_uploader :case_study, FileUploader
  mount_uploader :logo, FileUploader

  field :name
  field :code_climate_id
  field :code_climate_snippet
  field :code_climate_coverage_snippet
  field :is_active, type: Boolean, default: true
  field :start_date, type: Date
  field :end_date, type: Date
  field :managed_by
  field :image
  field :description
  field :url
  field :case_study, type: String
  field :logo
  field :visible_on_home_page, type: Boolean, default: false
  field :visible_on_website, type: Boolean, default: true
  # More Details
  field :ruby_version
  field :rails_version
  field :database
  field :database_version
  field :deployment_server
  field :deployment_script
  field :web_server
  field :app_server
  field :payment_gateway
  field :image_store
  field :index_server
  field :background_jobs
  field :sms_gateway
  field :other_frameworks
  field :other_details
  field :code, type: String
  field :number_of_employees, type: Integer
  field :invoice_date, type: Date

  slug :name

  has_and_belongs_to_many :users
  accepts_nested_attributes_for :users
  belongs_to :company

  validates_presence_of :name
  scope :all_active, ->{where(is_active: true).asc(:name)}
  scope :visible_on_website, -> {where(visible_on_website: true)}
  scope :sort_by_position, -> { asc(:position)}

  validates_uniqueness_of :code, allow_blank: true, allow_nil: true

  after_update do
    Rails.cache.delete('views/website/portfolio.json') if updated_at_changed?
  end

  def self.get_all_sorted_by_name
    Project.all.asc(:name)
  end

  def tag_name(field)
    case field
      when :ruby_version
        "Ruby " + self.ruby_version if ruby_version.present?
      when :rails_version
        "Rails " + rails_version if rails_version.present?
      when :other_frameworks
        self.try(field).split(',')
      when :other_details
        self.try(field).split(',')
      when :database
       "#{self.database} " + self.try(:database_version).to_s
      else
        self.try(field)
    end
  end

  def tags
    tags = []
    [:ruby_version, :rails_version, :database,:deployment_server, :deployment_script, :web_server, :app_server,
      :payment_gateway, :image_store, :background_jobs, :other_frameworks, :other_details].each do |field|
       tags << self.tag_name(field) if self.try(field).present?
    end
    tags.compact.flatten
  end

  def self.to_csv(options = {})
    column_names = ['name', 'code_climate_id', 'code_climate_snippet', 'code_climate_coverage_snippet', 'is_active', 'start_date', 'end_date', 'managed_by', 'ruby_version', 'rails_version', 'database', 'database_version', 'deployment_server', 'deployment_script', 'web_server', 'app_server', 'payment_gateway', 'image_store', 'index_server', 'background_jobs', 'sms_gateway', 'other_frameworks', 'other_details']
    CSV.generate(options) do |csv|
      csv << column_names.collect(&:titleize)
      all.each do |project|
        csv << project.attributes.values_at(*column_names)
      end
    end
  end
end
