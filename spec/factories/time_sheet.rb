FactoryGirl.define do
  factory :time_sheet do
    project_id FactoryGirl.create(:project).id
    date Date.parse('14-07-2018')
    from_time Time.parse('14-07-2018 6:00')
    to_time Time.parse('14-07-2018 7:00')
    description 'test'
  end
end