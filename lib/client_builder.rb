require 'google/api_client'

class ClientBuilder
  def self.build_client
    if Rails.env.test?
      key_file = "#{Rails.root}/config/service_account_key_test.p12"
    else
      key_file = "#{Rails.root}/config/service_account_key.p12"
    end
    key_secret = 'notasecret'

    @key = Google::APIClient::KeyUtils.load_from_pkcs12(key_file, key_secret)
    @client = Google::APIClient.new application_name: "Intranet", application_version: "0.0.1"
    authorize_client
    @client.authorization.fetch_access_token!
    @client
  end

  def self.authorize_client
    @client.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => 'https://www.googleapis.com/auth/calendar',
      :issuer => ENV['SERVICE_ACCOUNT_EMAIL'],
      :grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      :access_type => 'offline',
      :signing_key => @key
    )
  end
end
