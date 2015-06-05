class Project
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  field :code_climate_id
  field :code_climate_snippet
  field :code_climate_coverage_snippet
  field :is_active, type: Boolean, default: true
  field :start_date, type: Date
  field :end_date, type: Date
  field :managed_by

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

  slug :name

  has_and_belongs_to_many :users
  accepts_nested_attributes_for :users
  validates_presence_of :name
  
  scope :all_active, ->{where(is_active: true).asc(:name)}

  def self.get_all_sorted_by_name
    Project.all.asc(:name)
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
