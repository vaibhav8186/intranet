require 'csv'
require 'pry'

header = ["Company Name", "GST number",
"Website",
"Projects",
"Accountat Name",
"Accountat Email",
"Accountat Phone number",
"Technical Person  Name",
"Technical Email",
"Technical Phone number",
"Company address",
"City",
"State",
"Landline no",
"Pin code"].map(&:strip)

CSV.foreach("sample.csv", :headers => true) do |row|
  company = Company.new
  company.name = row["Company Name"]
  company.gstno = row["GST number"]
  company.website = row["Website"]

  if company.save
    accountat = company.contact_persons.build
    accountant.name = row["Accountat Name"]
    accountant.email = row["Accountat Email"]
    accountant.phone_no = row["Accountat Phone number"]
    accountat.save

    technical = company.contact_persons.build
    technical.name = row["Technical Person Name"]
    technical.email = row["Technical Email"]
    technical.phone_no = row["Technical Phone number"]
    technical.save

    address = company.addresses.build
    address.address = row["Company address"]
    address.city = row["City"]
    address.state = row["State"]
    address.landline_no = row["Landline no"]
    address.pin_code = row["Pin code"]
    address.save
  end
end
