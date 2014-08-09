require 'google/api_client'

class ClientBuilder

  def self.get_client(user)
    client = Google::APIClient.new
    client.authorization.scope = 'https://www.googleapis.com/auth/calendar'
    client.authorization.access_token = get_current_token(user)
    client
  end

  def self.get_current_token(user)
    if (DateTime.strptime(User.last.expires_at.to_s,"%s") < DateTime.now.utc || user.access_token == nil) 
     client= Google::APIClient.new
     client.authorization.client_id= GOOGLE_API_CLIENT_ID
     client.authorization.client_secret= GOOGLE_API_CLIENT_SECRET
     client.authorization.grant_type= 'refresh_token'
     client.authorization.refresh_token= user.refresh_token
     re= client.authorization.fetch_access_token!

     user.access_token= re['access_token']
     user.expires_at= Time.now.to_i + re['expires_in']
     user.save

    end
      user.access_token
  end
end