require 'spec_helper'

describe CalendarApi do
  before(:each) do
    @event = {
      'summary'=> "Silly Event",
      'start'=> {'dateTime' => DateTime.tomorrow.strftime("%Y-%m-%dT%H:%M:%S+05:30") },
      'end'=>   {'dateTime' => DateTime.tomorrow.strftime("%Y-%m-%dT%H:%M:%S+05:30") },
    }
  end

  context "#create_event" do

    context "create new event and check status as confirmed" do
      before do
        @result = CalendarApi.create_event(@event)
        @event_body = JSON.load(@result.response.env.body)
      end

      it { expect(@event_body['status']).to eql('confirmed') }

      after do
        # Delete created evented from calendar
        CalendarApi.delete_event(@event_body['id'])
      end
    end

    context "return error if end time is not present" do
      before do
        @event['end'] = nil
        @result = CalendarApi.create_event(@event)
        @event_body = JSON.load(@result.response.env.body)
      end

      it { expect(@event_body['error']['message']).to eql("Missing end time.") }
      it { expect(@result.response.env.status).to eql(400) }
    end

    context "return nil if event is outdated" do
      before do
        @event['start']['dateTime'] = DateTime.yesterday.strftime("%Y-%m-%dT%H:%M:%S+05:30")
        @result = CalendarApi.create_event(@event)
      end

      it { expect(@result).to eql(nil) }
    end
  end

  context "#delete_event" do
    before do
      result = CalendarApi.create_event(@event)
      @event_id = JSON.load(result.response.env.body)['id']
    end

    # successfull request with empty response body
    context "delete event for given id" do
      it { expect(CalendarApi.delete_event(@event_id).response.env.status).to eql(204) }
    end
  end

  context "#update_event" do
    before do
      result = CalendarApi.create_event(@event)
      @event_id = JSON.load(result.response.env.body)['id']
      
      @event['summary'] = "Silly Event again"
      @result = CalendarApi.update_event(@event_id, @event)
      @event_body = JSON.load(@result.response.env.body)
    end

    context "update event summary gives its id" do
      it { expect(@event_body['summary']).to eql("Silly Event again") }
    end

    after do  
      # Delete created evented from calendar
      CalendarApi.delete_event(@event_id)
    end
  end
end
