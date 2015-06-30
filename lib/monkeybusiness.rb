require 'aws-sdk'
require 'csv'
require 'date'
require 'hashie'
require 'logging'
require 'pp'
require 'pry-plus'
require 'sequel'
require 'surveymonkey'
require 'timeliness'
require 'zlib'

require 'monkeybusiness/components'
require 'monkeybusiness/version'

module Monkeybusiness
  def self.run
    begin
      today = Time.now
      yesterday = Monkeybusiness::Worker.previous_day(today)

      # write out survey table headers
      MonkeyBusiness::SurveyRow.write!(MonkeyBusiness::SurveyRow.headers, MonkeyBusiness::SurveyRow.default_outfile)
      MonkeyBusiness::SurveyQuestionRow.write!(MonkeyBusiness::SurveyQuestionRow.headers, MonkeyBusiness::SurveyQuestionRow.default_outfile)
      MonkeyBusiness::SurveyResponseOptionRow.write!(MonkeyBusiness::SurveyResponseOptionRow.headers, MonkeyBusiness::SurveyResponseOptionRow.default_outfile)
      MonkeyBusiness::SurveyResponseRow.write!(MonkeyBusiness::SurveyResponseRow.headers, MonkeyBusiness::SurveyResponseRow.default_outfile)


      target_survey = '61225411'
      target_questions = ['762673420' ]
      # target_questions = ['762673420', '762667811' ]
      # target_questions = []
      target_respondents = ['4025256245']
      # target_respondents = []

      worker = Monkeybusiness::Worker.new

      worker.process_surveys(target_survey, yesterday, target_questions, target_respondents)

      # upload compressed archives to S3
      s3_prefix = 'test'
      MonkeyBusiness::SurveyRow.upload(s3_prefix)
      MonkeyBusiness::SurveyQuestionRow.upload(s3_prefix)
      MonkeyBusiness::SurveyResponseOptionRow.upload(s3_prefix)
      MonkeyBusiness::SurveyResponseRow.upload(s3_prefix)

      # import to Redshift
      connection_string = sprintf("postgres://%s:%s@%s:%s/%s", 'rkevents', 'uHEahL73ZQbZKcicNXWG', 'localhost', '5439', 'rkevents')
      MonkeyBusiness::SurveyQuestionRow.dbimport(connection_string, s3_prefix)

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
