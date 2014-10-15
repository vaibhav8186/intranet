require 'google/api_client'
require 'client_builder'

class CalendarApi

  def self.establish_client
    @client = ClientBuilder.build_client
    @service = @client.discovered_api('calendar', 'v3')
  end

  def self.share_calendar(email)
    establish_client
    body = {
      'role' => 'owner',
      'scope' => {
        'type' => 'user',
        'value' => email
      }
    }

    result = @client.execute(:api_method => @service.acl.insert,
                             :parameters => {'calendarId' => 'primary'},
                             :body => JSON.dump(body),
                             :headers => {'Content-Type' => 'application/json'})
  end

  def self.create_event(event)
    if event['start']['dateTime'] >= DateTime.now
      establish_client
      result = @client.execute(:api_method => @service.events.insert,
                               :parameters => {'calendarId' => 'primary', 
                                               'sendNotifications' => true},
                               :body => JSON.dump(event),
                               :headers => {'Content-Type' => 'application/json'})
    end
    result
  end

  def self.get_event(id)  
    establish_client
    result = @client.execute(:api_method => @service.events.get,
                             :parameters => {'calendarId' => 'primary', 'eventId' => id})
  end

  def self.delete_event(id)
    establish_client
    result = @client.execute(:api_method => @service.events.delete,
                             :parameters => {'calendarId' => 'primary', 
                                             'eventId' => id, 
                                             'sendNotifications' => true})
  end

  def self.update_event(id, event)
    establish_client
    result = @client.execute(:api_method => @service.events.update,
                             :parameters => {'calendarId' => 'primary', 
                                             'eventId' => id, 
                                             'sendNotifications' => true},
                             :body => JSON.dump(event),
                             :headers => {'Content-Type' => 'application/json'})
  end
end
