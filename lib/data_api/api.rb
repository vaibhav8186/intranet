require 'net/http'

module Api
  class Bonusly

    def initialize(token)
      @uri = URI.parse('https://bonus.ly/api/v1/bonuses')
      @token = token
      @http = Net::HTTP.new(@uri.host, @uri.port)
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    def bonusly_messages(options = {})
      params = "access_token=#{@token}"
      options.each_pair { |key, value| params += "&#{key}=#{value}" }
      response = @http.get(@uri.path + "?" + params)
      
      begin
        body = JSON.parse(response.body)
      rescue
        body = { 'success' => false, 'message' => 'User not listed in Bonusly' }
      end
      body['success'] ? body['result'] : body['message']
    end
  end
end
