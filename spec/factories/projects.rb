# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :project do
    name "The pediatric network"
    code_climate_id "12345"
    code_climate_snippet "Intranet Snipate Text"
    code "ASDF2D"
  end
end
