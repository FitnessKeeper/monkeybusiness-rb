require 'monkeybusiness/components'
require 'monkeybusiness/monkeylogging'

module MonkeyBusiness

  include MonkeyBusiness::MonkeyLogging

  class Worker
    attr_accessor :date, :survey_id, :question_ids, :respondent_ids

    def initialize(survey_id, question_ids = [], respondent_ids = [])
      begin
        @survey_id = survey_id
        @question_ids = question_ids
        @respondent_ids = respondent_ids

      rescue StandardError => e
        raise e
      end
    end

    def get_survey_details(survey_id = self.survey_id)
      begin
        response = Surveymonkey.get_survey_details({'method_params' => survey_id})

        if response['status'] == 0
          MonkeyBusiness::Survey.new(response.fetch('data'))
        end
      rescue StandardError => e
        binding.pry
        raise e
      end
    end

    def get_responses(survey, respondents)
      @log = Logging.logger[__method__]
      @log.level = :debug

      respondent_list = respondents.respondents.clone
      responses = []

      # bundle the respondent_ids into blocks of 100
      response_bundles = []
      while respondent_list.length > 0 do

        bundle = respondent_list.shift(100)
        response_bundles.push(bundle.collect {|respondent| respondent.respondent_id})
      end

      response_bundles.each do |bundle|
        method_params = {'survey_id' => survey.survey_id, 'respondent_ids' => bundle}

        response_bundle = Surveymonkey.get_responses('method_params' => method_params)

        responses.concat(response_bundle.fetch('data', []).collect { |respondent| MonkeyBusiness::Responses.new(respondent) })
      end

      responses

    end

    def get_respondents(survey, respondents = [])
      @log = Logging.logger[__method__]
      @log.level = :debug

      method_params = {'survey_id' => survey.survey_id, 'fields' => ['date_start', 'date_modified', 'custom_id']}

      respondent_list = Surveymonkey.get_respondent_list(method_params).fetch('data', {}).fetch('respondents', [])

      if respondents.length > 0
        respondent_list.select! { |respondent| respondents.include?(respondent['respondent_id']) }
      end

      MonkeyBusiness::Respondents.new({'respondents' => respondent_list, 'survey' => survey})

    end

    def process_surveys(survey_id = self.survey_id, question_ids = self.question_ids, respondent_ids = self.respondent_ids)
      log = Logging.logger[__method__]
      log.level = :debug

      begin
        if survey_id.nil?
          surveys = get_surveys
        else
          surveys = [{'survey_id' => survey_id}]
        end

        surveys.each do |survey_id|
          survey = get_survey_details(survey_id)


          # write the survey row
          MonkeyBusiness::SurveyRow.new(survey).write

          # get the respondents
          if respondent_ids.length == 0
            respondents = get_respondents(survey)
          else
            respondents = get_respondents(survey, respondents = respondent_ids)
          end

          # process the survey responses
          responses = get_responses(survey, respondents)

          if question_ids.length == 0
            the_questions = survey.questions
          else
            the_questions = survey.questions.select { |question| question_ids.include?(question.question_id) }
          end

          the_questions.each do |question|
            # write the question row
            MonkeyBusiness::SurveyQuestionRow.new(question, survey).write

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

            if question_ids.length > 0
              questions_answered.select! { |question| question_ids.include?(question.question_id) }
            end

            respondents_questions.store(respondent_id, questions_answered)
          end # response

          # process the responses

          responses.each do |response|
            respondent = respondents.respondents.select { |r| r.respondent_id == response.respondent_id }[0]

            if respondent.nil?
            else
              respondents_questions.fetch(respondent.respondent_id, []).each do |the_response|

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
  end
end
