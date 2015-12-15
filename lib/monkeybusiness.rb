require 'aws-sdk'
require 'csv'
require 'date'
require 'erb'
require 'hashie'
require 'logging'
require 'pp'
require 'pry'
require 'surveymonkey'
require 'timeliness'
require 'zlib'

require 'monkeybusiness/components'
require 'monkeybusiness/worker'
require 'monkeybusiness/version'
require 'monkeybusiness/api'

module MonkeyBusiness
  def self.run(survey_id, initial = false, target_questions = [], target_respondents = [], s3_prefix = 'monkeybusiness')
    begin
      # write out survey table headers
      MonkeyBusiness::SurveyRow.write!(MonkeyBusiness::SurveyRow.headers, MonkeyBusiness::SurveyRow.default_outfile, true)
      MonkeyBusiness::SurveyQuestionRow.write!(MonkeyBusiness::SurveyQuestionRow.headers, MonkeyBusiness::SurveyQuestionRow.default_outfile, true)
      MonkeyBusiness::SurveyResponseOptionRow.write!(MonkeyBusiness::SurveyResponseOptionRow.headers, MonkeyBusiness::SurveyResponseOptionRow.default_outfile, true)
      MonkeyBusiness::SurveyResponseRow.write!(MonkeyBusiness::SurveyResponseRow.headers, MonkeyBusiness::SurveyResponseRow.default_outfile, true)

      # download the survey data
      MonkeyBusiness::Worker.new(survey_id, target_questions, target_respondents).process_surveys

      # upload compressed archives to S3
      prefixed_path = File.join(s3_prefix, survey_id)

      MonkeyBusiness::SurveyRow.upload(prefixed_path)
      MonkeyBusiness::SurveyQuestionRow.upload(prefixed_path)
      MonkeyBusiness::SurveyResponseOptionRow.upload(prefixed_path)
      MonkeyBusiness::SurveyResponseRow.upload(prefixed_path)

    rescue StandardError => e
      raise e
    end
  end

  def self.get_surveys(title = nil, detail = nil)
    begin
      if detail
        method_params = {'fields' => ['title','date_created','date_modified','question_count','num_responses']}
      else
        method_params = {}
      end

      if title
        method_params.merge!({'title' => title})
      end

      Surveymonkey.get_survey_list(method_params).fetch('data', {}).fetch('surveys', [])
    rescue StandardError => e
      raise e
    end
  end

end
