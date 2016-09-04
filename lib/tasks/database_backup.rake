task :database_backup => :environment do |task,args|
  
  dir_path = File.expand_path("~/database_backup")
  filename = "#{Date.today.day}_#{Date.today.month}"

  output_dir_path = "#{dir_path}/#{filename}"
 
  #create ouptput dir 
  Dir.mkdir(output_dir_path) unless Dir.exist?(output_dir_path)
  
  #Delete all database backups which are taken 1 month before

  Dir.glob("#{dir_path}/**").each do |dir|
    FileUtils.rm_rf(dir) if File.ctime(dir).to_i < 1.month.ago.to_i
  end

  system "mongodump -d intranet_#{Rails.env} -o #{output_dir_path}"
  system "cd #{dir_path} && tar -C #{dir_path} -zcvf #{filename}.tar.gz #{filename}"

  p "Database backup email"
  UserMailer.database_backup(dir_path, "#{filename}.tar.gz").deliver
  p "sent"
end
