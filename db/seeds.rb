# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#

admin = User.create(email: "Administrator@joshsoftware.com", password: "josh123", role: "Super Admin")
hr = User.create(email: "hr@joshsoftware.com", password: "josh123", role: "HR")
LeaveType.collection.insert(
  [ {name: 'Sick', number_of_days: SICK_LEAVE},
    {name: 'Casual', number_of_days: CASUAL_LEAVE},
    {name: 'Previlege', number_of_days: PRIVILEGE_LEAVE}
  ])
admin.build_public_profile(first_name: "Josh", last_name: "Admin").save
hr.build_public_profile(first_name: "Josh", last_name: "HR").save
