require 'monkeybusiness/components'
require 'monkeybusiness/monkeylogging'

module MonkeyBusiness

  include MonkeyBusiness::MonkeyLogging

  class Worker
    attr_accessor :date, :survey_id, :question_ids, :respondent_ids

    def initialize(survey_id, date = nil, question_ids = [], respondent_ids = [])
      begin
        @survey_id = survey_id
        @date = date
        @question_ids = question_ids
        @respondent_ids = respondent_ids

      rescue StandardError => e
        raise e
      end
    end

    def get_survey_details(survey_id = self.survey_id)
      response = Surveymonkey.get_survey_details('method_params' => survey_id)

      if response['status'] == 0
        MonkeyBusiness::Survey.new(response.fetch('data'))
      end
    end

    def get_responses(survey, respondents, start_date = nil, end_date = nil)
      @log = Logging.logger[__method__]
      @log.level = :debug

      respondent_list = respondents.respondents.clone
      responses = []

      # bundle the respondent_ids into blocks of 100
      response_bundles = []
      while respondent_list.length > 0 do
        @log.debug sprintf("%s should have %i responses, actually has %i responses", survey, survey.num_responses.to_i, respondents.respondents.length)

        bundle = respondent_list.shift(100)
        response_bundles.push(bundle.collect {|respondent| respondent.respondent_id})
        @log.debug sprintf("prepared %i response bundles", response_bundles.length)
      end

      response_bundles.each do |bundle|
        method_params = date_params({'survey_id' => survey.survey_id, 'respondent_ids' => bundle}, start_date, end_date)

        response_bundle = Surveymonkey.get_responses('method_params' => method_params)

        responses.concat(response_bundle.fetch('data', []).collect { |respondent| MonkeyBusiness::Responses.new(respondent) })
        @log.debug sprintf("collected %i of %i responses to %s", responses.length, survey.num_responses.to_i, survey)
      end

      responses

    end

    def get_respondents(survey, start_date = nil, end_date = nil, respondents = [])
      @log = Logging.logger[__method__]
      @log.level = :debug

      method_params = date_params({'survey_id' => survey.survey_id, 'fields' => ['date_start', 'date_modified', 'custom_id']}, start_date, end_date, 'start_modified_date', 'end_modified_date')

      respondent_list = Surveymonkey.get_respondent_list(method_params).fetch('data', {}).fetch('respondents', [])

      if respondents.length > 0
        respondent_list.select! { |respondent| respondents.include?(respondent['respondent_id']) }
      end

      MonkeyBusiness::Respondents.new({'respondents' => respondent_list, 'survey' => survey})

    end

    def process_surveys(survey_id = self.survey_id, date = self.date, question_ids = self.question_ids, respondent_ids = self.respondent_ids)
      log = Logging.logger[__method__]
      log.level = :debug

      begin
        if survey_id.nil?
          surveys = get_surveys
        else
          surveys = [{'survey_id' => survey_id}]
        end

        if date.nil?
          start_date = nil
          end_date = nil
        else
          end_date = date_meridian(previous_day(Surveymonkey::DateString.new(date).to_s))
          start_date = date_meridian(previous_day(end_date))
          log.debug sprintf("start_date %s, end_date %s", start_date, end_date)
        end

        surveys.each do |survey_id|
          survey = get_survey_details(survey_id)

          log.debug sprintf("processing survey %s", survey)

          # write the survey row
          MonkeyBusiness::SurveyRow.new(survey).write

          # get the respondents
          log.debug sprintf("getting respondents for survey %s", survey)
          if respondent_ids.length == 0
            respondents = get_respondents(survey, start_date = nil, end_date = nil)
          else
            respondents = get_respondents(survey, start_date = nil, end_date = nil, respondents = respondent_ids)
          end

          # process the survey responses
          log.debug sprintf("getting responses for survey %s", survey)
          responses = get_responses(survey, respondents, start_date, end_date)

          if question_ids.length == 0
            the_questions = survey.questions
          else
            the_questions = survey.questions.select { |question| question_ids.include?(question.question_id) }
          end

          log.debug sprintf("processing %i questions for survey %s", the_questions.length, survey)
          the_questions.each do |question|
            # write the question row
            MonkeyBusiness::SurveyQuestionRow.new(question, survey).write

            log.debug sprintf("processing %i answers for question %s", question.answers.length, question)
            question.answers.each do |answer|
              # write the answer row
              MonkeyBusiness::SurveyResponseOptionRow.new(answer, question).write
            end # responseoption
          end # question

          # map respondents to questions
          respondents_questions = {}

          responses.each do |response|
            respondent_id = response.respondent_id
            questions_answered = response.questions.clone
            log.debug sprintf("determining questions responded to by respondent %s", respondent_id)

            if question_ids.length > 0
              questions_answered.select! { |question| question_ids.include?(question.question_id) }
            end

            # log.debug sprintf("respondent %s responded to questions %s", respondent_id, questions_answered.sort.each { |question| question.to_s }.join(','))
            log.debug sprintf("respondent %s responded to %i questions", respondent_id, questions_answered.length)
            respondents_questions.store(respondent_id, questions_answered)
          end # response

          # process the responses

          responses.each do |response|
            respondent = respondents.respondents.select { |r| r.respondent_id == response.respondent_id }[0]

            if respondent.nil?
              log.warn sprintf("no response from respondent %s found for survey %s, question %s", respondent, survey, question)
            else
              respondents_questions.fetch(respondent.respondent_id, []).each do |the_response|
                log.debug sprintf("processing %i answers from respondent %s for question %s", the_response.answers.length, respondent, the_response.question_id)

                the_response.answers.each do |answer|
                  MonkeyBusiness::SurveyResponseRow.new(answer, survey, the_response.question_id, respondent).write
                end # answer
              end # the_response

            end # no respondent?

          end # response

        end # survey

      rescue StandardError => e
        raise e
      end
    end

    def self.previous_day(input)
      begin
        case input
        when Time,Date,DateTime
          time = input
        else
          time = Surveymonkey::DateString.new(input).time
        end

        previous = time - (60 * 60 * 24)

        Surveymonkey::DateString.new(previous).to_s

      rescue StandardError => e
        raise e
      end
    end

    def previous_day(input)
      self.class.send(:previous_day, input)
    end

    def self.date_meridian(input)
      begin
        case input
        when Time,Date,DateTime
          time = input
        else
          time = Surveymonkey::DateString.new(input).time
        end

        time.to_s.split(' ').shift.concat(' 00:00:00')

      rescue StandardError => e
        raise e
      end
    end

    def date_meridian(input)
      self.class.send(:date_meridian, input)
    end

    def self.date_params(method_params, start_date = nil, end_date = nil, start_key = 'start_date', end_key = 'end_date')
      begin
        if ( start_date.nil? or end_date.nil? )
          method_params
        else
          method_params.merge({start_key.to_s => start_date, end_key.to_s => end_date})
        end

      rescue StandardError => e
        raise e
      end
    end

    def date_params(method_params, start_date = nil, end_date = nil, start_key = 'start_date', end_key = 'end_date')
      self.class.send(:date_params, method_params, start_date = nil, end_date = nil, start_key = 'start_date', end_key = 'end_date')
    end

  end
end
