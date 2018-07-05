require 'csv'

task import_companies: [:environment] do
  header = ["Company Name",
  "GST number",
  "Website",
  "Projects",
  "Accountant Name",
  "Accountant Email",
  "Accountant Phone number",
  "Technical Person Name",
  "Technical Email",
  "Technical Phone number",
  "Company address",
  "City",
  "State",
  "Landline no",
  "Pin code"].map(&:strip)

  def import_company(row)
    company = Company.new
    company.name = row["Company Name"]
    company.gstno = row["GST number"]
    company.website = parse_website(row["Website"])
    assign_companies_to_projects(row["Projects"], company) if row["Projects"].present?
    if company.save
      create_technical_person(company, row) if row["Technical Email"].present?
      create_accountant(company, row) if row["Accountant Email"].present?
      create_address(company, row) if row["Company address"].present?
    end
    company
  end

  def parse_website(website)
    website.start_with?("http") ? website : "https://#{website}" if website.present?
  end

  def assign_companies_to_projects(project_names, company)
    project_names =  project_names.try(:split, "|").try(:map, &:strip) || []
    Project.in(name: project_names).update_all(company_id: company.id)
  end

  def create_accountant(company, row)
    accountant = company.contact_persons.build
    accountant.name = row["Accountant Name"]
    accountant.email = row["Accountant Email"]
    accountant.phone_no = row["Accountant Phone number"]
    accountant.role = "Accountant"
    accountant.save
  end

  def create_technical_person(company, row)
    technical = company.contact_persons.build
    technical.name = row["Technical Person Name"]
    technical.email = row["Technical Email"]
    technical.phone_no = row["Technical Phone number"]
    technical.role = "Technical"
    technical.save
  end

  def create_address(company, row)
    address = company.addresses.build
    address.address = row["Company address"]
    address.city = row["City"]
    address.state = row["State"]
    address.landline_no = row["Landline no"]
    address.pin_code = row["Pin code"]
    address.save
  end

  file = File.open('import_companies_log.csv', 'w')
  file.puts "Index, Response, Company Name, Error Messages"
  CSV.foreach("public/companies.csv", headers: true).with_index(1) do |row, index|
    company = import_company(row)
    if company.invalid?
      puts "ERROR - Importing #{company.name}"
      file.puts "#{index}, error, #{company.name}, #{company.errors.full_messages.join('|')}"
    else
      puts "#{index} - #{company.name} Imported Successfully"
      file.puts "#{index}, success, #{company.name}"
    end
  end
  file.close
end
