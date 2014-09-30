require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
#require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
require 'mina/rvm'    # for rvm support. (http://rvm.io)
require 'mina_extensions/sidekiq'

#Basic settings:
#domain       - The hostname to SSH to.
#deploy_to    - Path to deploy into.
#repository   - Git repo to clone from. (needed by mina/git)
#branch       - Branch name to deploy. (needed by mina/git)

env = ENV['on'] || 'production'
nocron = ENV['nocron'] || false
branch = ENV['branch'] || 'master'
#bkp = ENV['bkp'] || false #Backup will be used for actual production 
index = ENV['index'] || false

if env == 'production'
  ip = '162.243.86.174'
  #branch = 'develop' # Always production!!
else
  #staging
  ip = '74.207.241.229'
end
set :term_mode, nil
set :domain, ip
set :user, 'deploy'
set :identity_file, "#{ENV['HOME']}/.ssh/id_joshsite_rsa"
set :deploy_to, "/home/deploy/projects/intranet/#{env}"
set :repository, 'git@github.com:joshsoftware/intranet.git'
set :branch, branch
set :rails_env, env

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/mongoid.yml', 'log', 'tmp', 'public/system', 
					'public/uploads', 'config/initializers/secret_token.rb', "config/initializers/smtp_gmail.rb", "db/seeds.rb",
          "config/initializers/constants.rb", "config/rnotifier.yaml", "config/environment.yml", 'config/service_account_key.p12']

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  invoke :'rvm:use[2.1.0]'
  
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config/initializers"]
  queue! %[chmod -R g+rx,u+rwx "#{deploy_to}/shared/config"]
  queue! %[touch "#{deploy_to}/shared/config/initializers/secret_token.rb"]
   
  queue! %[touch "#{deploy_to}/shared/config/initializers/smtp_gmail.rb"]
  queue! %[touch "#{deploy_to}/shared/config/initializers/constants.rb"]

  queue! %[touch "#{deploy_to}/shared/config/mongoid.yml"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config/mongoid.yml"]

  queue! %[touch "#{deploy_to}/shared/config/rnotifier.yaml"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config/rnotifier.yaml"]
  
  queue! %[mkdir -p "#{deploy_to}/shared/tmp"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp"]

  queue! %[mkdir -p "#{deploy_to}/shared/tmp/pids"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/pids"]

  queue! %[mkdir -p "#{deploy_to}/shared/public/system"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/system"]
  
  queue! %[mkdir -p "#{deploy_to}/shared/public/uploads"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/uploads"] 
 
  queue! %[mkdir -p "#{deploy_to}/shared/pids/"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/pids"]

  queue! %[mkdir -p "#{deploy_to}/shared/db/"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/db/"]
  queue! %[touch g+rx,u+rwx "#{deploy_to}/shared/db/seeds.rb"]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:assets_precompile'

    to :launch do

      # Index if required
      if index
        queue "cd #{deploy_to}/current && bundle exec rake db:mongoid:create_indexes RAILS_ENV=#{env}"
      end

            

      # SIDEKIQ restart
            #queue "cd #{deploy_to}/current && nohup sidekiq -e RAILS_ENV=#{env} &"
      #queue "sudo monit restart sidekiq"

      # Update whenever 
      unless nocron
        queue "cd #{deploy_to}/current && bundle exec whenever -i intranet_whenever_tasks --update-crontab --set 'environment=#{env}'"
      end

      # Take backup if required
      #if bkp
      #  queue "export LC_ALL=C; /opt/mongo/bin/mongodump -d qwikcom_staging -o /data/bkp/#{Date.today.strftime("%Y%m%d")}.dump"
      #end
      
      invoke 'application:restart'
    end
    
       
  end
end
namespace :passenger do
  task :restart_passenger do
    queue "touch #{deploy_to}/current/tmp/restart.txt"
  end
end

namespace :nginx do
  desc 'stop'
  task :stop do
    queue "sudo service nginx stop"
  end

  desc 'start'
  task :start do
    queue "sudo service nginx start"
  end

  desc 'restart'
  task :restart do
    invoke 'nginx:stop'
    invoke 'nginx:start'
  end
end

namespace :application do
  desc 'Start the application'
  task :start => :environment do
    invoke 'passenger:restart_passenger'
    #we need to stop & start the sidekiq server again
    invoke :'sidekiq:quiet' 
    invoke :'sidekiq:stop' 
    invoke :'sidekiq:start'
  end

  desc 'Stop the application'
  task :stop => :environment do
    invoke :'sidekiq:quiet' 
    invoke :'sidekiq:stop'
  end

  desc 'Restart the application'
  task :restart => :environment do
    invoke 'application:stop'
    invoke 'application:start'
  end
end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers
