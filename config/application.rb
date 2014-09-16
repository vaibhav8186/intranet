require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)
Date::DATE_FORMATS[:default] = '%d/%m/%Y'
Time::DATE_FORMATS[:default] = '%d/%m/%Y - %H:%M %p'

module Intranet
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.autoload_paths += Dir["#{config.root}/lib", "#{config.root}/lib/**/"]
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'environment.yml')
      
      environment_yml = YAML.load(File.open(env_file)).detect do |key, value| 
        Rails.env == key.to_s
      end if File.exist?(env_file)

      environment_yml.last.each do |key,value|
        ENV[key.to_s] = value
      end if environment_yml.present?
    end
    # config.i18n.default_locale = :de
  end
end
