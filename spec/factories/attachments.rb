# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :attachment do
    name "Photo"
    document { fixture_file_upload('spec/fixtures/files/sample1.pdf') }
  end
end
