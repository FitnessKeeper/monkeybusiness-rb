require 'aws-sdk'
require 'csv'
require 'date'
require 'hashie'
require 'logging'
require 'pp'
require 'pry'
require 'sequel'
require 'surveymonkey'
require 'timeliness'
require 'zlib'

require 'monkeybusiness/components'
require 'monkeybusiness/worker'
require 'monkeybusiness/version'

module MonkeyBusiness
  def self.run(survey_id, initial = false, target_questions = [], target_respondents = [], s3_prefix = 'monkeybusiness')
    begin
      # write out survey table headers
      MonkeyBusiness::SurveyRow.write!(MonkeyBusiness::SurveyRow.headers, MonkeyBusiness::SurveyRow.default_outfile, true)
      MonkeyBusiness::SurveyQuestionRow.write!(MonkeyBusiness::SurveyQuestionRow.headers, MonkeyBusiness::SurveyQuestionRow.default_outfile, true)
      MonkeyBusiness::SurveyResponseOptionRow.write!(MonkeyBusiness::SurveyResponseOptionRow.headers, MonkeyBusiness::SurveyResponseOptionRow.default_outfile, true)
      MonkeyBusiness::SurveyResponseRow.write!(MonkeyBusiness::SurveyResponseRow.headers, MonkeyBusiness::SurveyResponseRow.default_outfile, true)

      MonkeyBusiness::Worker.new(survey_id, target_questions, target_respondents).process_surveys

      # upload compressed archives to S3
      prefixed_path = File.join(s3_prefix, survey_id)

      MonkeyBusiness::SurveyRow.upload(prefixed_path)
      MonkeyBusiness::SurveyQuestionRow.upload(prefixed_path)
      MonkeyBusiness::SurveyResponseOptionRow.upload(prefixed_path)
      MonkeyBusiness::SurveyResponseRow.upload(prefixed_path)

      # import to Redshift
      connection_params = { client_min_messages: false, force_standard_strings: false }
      MonkeyBusiness::SurveyResponseRow.dbimport(survey_id, prefixed_path, connection_params)

      if initial
        MonkeyBusiness::SurveyRow.dbimport(survey_id, prefixed_path, connection_params)
        MonkeyBusiness::SurveyQuestionRow.dbimport(survey_id, prefixed_path, connection_params, false)
        MonkeyBusiness::SurveyResponseOptionRow.dbimport(survey_id, prefixed_path, connection_params)
      end

    rescue StandardError => e
      raise e
    end
  end

  def self.get_surveys
    begin
      Surveymonkey.get_survey_list.fetch('data', {}).fetch('surveys', [])
    rescue StandardError => e
      raise e
    end
  end

end
