require 'faker'

FactoryGirl.define do
  factory :website_contact do
    name Faker::Name.name
    email Faker::Internet.email
    skype_id Faker::String.random(5..10)
    phone Faker::PhoneNumber.phone_number
    message Faker::String.random(8..20)
  end
end