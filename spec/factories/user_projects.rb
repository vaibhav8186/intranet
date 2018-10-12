FactoryGirl.define do
  factory :user_project do
    start_date DateTime.now - 2
    end_date nil
  end
end