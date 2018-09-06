desc 'Copy user and project ids to user projects model'
task :copy_user_and_project_id => [:environment] do
  User.all.each do |user|
    user.project_ids.each do |project_id|
      UserProject.create!(user_id: user.id, project_id: project_id, start_date: '1/8/2018'.to_date, end_date: nil)
    end
  end
end