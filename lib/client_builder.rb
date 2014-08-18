require 'google/api_client'

class ClientBuilder
  def self.build_client
    key_file = "#{Rails.root}/config/service_account_key.p12"
    key_secret = 'notasecret'

    @key = Google::APIClient::KeyUtils.load_from_pkcs12(key_file, key_secret)
    @client = Google::APIClient.new application_name: "Intranet", application_version: "0.0.1"
    authorize_client
    @client.authorization.fetch_access_token!
    @client
  end

  def self.authorize_client
    service_account_email = Rails.env.production? ?
      '315732927493-5hpilt3p6m6ld542r8q21uc5fon9dhu5@developer.gserviceaccount.com' :
      '1099029398199-8eqlk4fv565gt9qas0ohc094ui5ovq4t@developer.gserviceaccount.com'

    @client.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => 'https://www.googleapis.com/auth/calendar',
      :issuer => service_account_email,
      :grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      :access_type => 'offline',
      :signing_key => @key
    )
  end
end
