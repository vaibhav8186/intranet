require 'faker'

FactoryGirl.define do
  factory :career do
    first_name          Faker::Name.first_name
    last_name           Faker::Name.last_name
    email               Faker::Internet.email
    contact_number      Faker::PhoneNumber.phone_number
    current_company     Faker::Company.name
    current_ctc         '8 Lakhs'
    linkedin_profile    Faker::Internet.url
    github_profile      Faker::Internet.url
    resume              { fixture_file_upload "/home/josh/redis.pdf" }
    portfolio_link      Faker::Internet.url
    cover               { fixture_file_upload "/home/josh/redis.pdf" }
  end
end