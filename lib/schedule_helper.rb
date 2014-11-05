class ScheduleHelper
	def self.make_event(schedule, datetime)
		event = {
			'summary'=> schedule.summary,
			'description'=> schedule.description,
			'start'=> {'dateTime' => datetime },
      'end' => {'dateTime' => datetime },
      'sequence' => schedule.sequence,

      'reminders' => {
        'useDefault' => false,
        'overrides' => [
          {'minutes' => 60, 'method' => 'email'}
        ]
      },

      'attendees'=> [
        {
          'email'=> schedule.candidate_details[:email],
          'displayName'=> "Interviewee",
        },
      ] 			
    }
    event
  end

  def self.convert_into_rfc3339(schedule)
    time = schedule.interview_time.to_s		
    #TimePicker returns today's date along with time. Hence manipulating string to take only time
    dt= schedule.interview_date.to_s + time[10, time.length]
    #DateTime getting parsed in GMT. Hence manipulating string into IST.
    tempdatetime= DateTime.parse(dt).rfc3339
    datetime =  tempdatetime[0,tempdatetime.length-5]+"05:30"

    datetime
  end
end
