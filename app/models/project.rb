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

  field :display_name
  field :is_free, type: Boolean, default: false

  slug :name

  has_many :time_sheets
  has_and_belongs_to_many :users, inverse_of: :projects
  accepts_nested_attributes_for :users
  belongs_to :company
  has_and_belongs_to_many :managers, class_name: 'User', foreign_key: 'manager_ids', inverse_of: :managed_projects
  validates_presence_of :name
  validate :project_code

  scope :all_active, ->{where(is_active: true).asc(:name)}
  scope :visible_on_website, -> {where(visible_on_website: true)}
  scope :sort_by_position, -> { asc(:position)}

  attr_accessor :allocated_employees, :manager_name, :employee_names
  # validates_uniqueness_of :code, allow_blank: true, allow_nil: true

  validates :display_name, format: { with: /\A[ ]*[\S]*[ ]*\Z/, message: "Name should not contain white space" }
  before_save do
    if name_changed? && display_name.blank?
      self.display_name = name.split.join('_')
    else
      self.display_name = self.display_name.try(:strip)
    end
  end


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
    column_names = ['name', 'code_climate_id', 'code_climate_snippet', 'code_climate_coverage_snippet', 'is_active', 'is_free', 'start_date', 'end_date', 'manager_name', 'number_of_employees', 'allocated_employees', 'employee_names', 'ruby_version', 'rails_version', 'database', 'database_version', 'deployment_server', 'deployment_script', 'web_server', 'app_server', 'payment_gateway', 'image_store', 'index_server', 'background_jobs', 'sms_gateway', 'other_frameworks', 'other_details']
    CSV.generate(options) do |csv|
      csv << column_names.collect(&:titleize)
      all.each do |project|
        project[:is_free] = project[:is_free] == false ? 'No' : 'Yes'
        project[:allocated_employees] = project.users.count
        project[:manager_name] = manager_names(project)
        project[:employee_names] = employee_names(project)
        csv << project.attributes.values_at(*column_names)
      end
    end
  end

  def self.manager_names(project)
    manager_names = []
    project.managers.each do |manager|
      manager_names << manager.name
    end
    manager_names.join(' | ')
  end

  def self.employee_names(project)
    employee_names = []
    project.users.each do |user|
      employee_names << user.name
    end
    employee_names.join(' | ')
  end

  def project_code
    return true if code.nil?
    project = Project.where(code: self.code).first
    if project.present?
      self.errors.add(:base, "Code already exists") unless
        project.company_id == self.company_id
    end
  end
end
