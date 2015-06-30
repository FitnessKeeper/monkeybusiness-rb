module MonkeyBusiness
  module MonkeyTime
    def previous_day(input)
      begin
        case input
        when Time,Date,DateTime
          time = input
        else
          time = Surveymonkey::DateString.new(day).time
        end

        previous = time - (60 * 60 * 24)

        Surveymonkey::DateString.new(previous).to_s

      rescue StandardError => e
        raise e
      end
    end
  end
end
