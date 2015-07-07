require 'monkeybusiness/monkeylogging'
require 'monkeybusiness/monkeyaws'
require 'monkeybusiness/monkeysql'

module MonkeyBusiness

  include MonkeyBusiness::MonkeyLogging
  include MonkeyBusiness::MonkeyAWS
  include MonkeyBusiness::MonkeySQL

  class Base < Hashie::Trash
    include Hashie::Extensions::Coercion
    include Hashie::Extensions::KeyConversion
    include Hashie::Extensions::IndifferentAccess
    include Hashie::Extensions::IgnoreUndeclared

    def initialize(attributes = {}, &block)
      begin
        super(attributes, &block)

        @log = Logging.logger[self]


      rescue StandardError => e
        raise e
      end
    end

    def to_s
      self.survey_id
    end

    def <=>(other)
      self.survey_id <=> other.survey_id
    end
  end

  class Survey < Base
    # storing complicated lambdas in variables for readability
    extract_custom_variables = lambda do |cvar|
      { cvar.fetch('question_id') => cvar.fetch('variable_label') }
    end

    extract_questions_from_pages = lambda do |pages|
      questions = pages.collect do |page|
        page.fetch('questions').collect do |question|
          MonkeyBusiness::SurveyQuestion.new(question)
        end
      end

      questions.flatten
    end

    property :survey_id, required: true
    property :language_id, required: true
    property :num_responses, required: true
    property :nickname, required: true
    property :title_text, from: :title, with: lambda { |title| title.fetch('text', '') }
    property :custom_variables, with: extract_custom_variables
    property :questions, required: true, from: :pages, with: extract_questions_from_pages

    def initialize(attributes = {}, &block)
      begin
        super(attributes, &block)

        @log = Logging.logger[self]
        @log.level = :debug

      rescue StandardError => e
        raise e
      end
    end

    def to_s
      sprintf("%s (%s)", self.survey_id, self.title_text)
    end
  end

  class ResponseOption < Base
    property :answer_id, required: true
    property :position, default: 0
    property :text, default: ''
    property :type, required: true
    property :visible, required: true

    coerce_key :visible, ->(v) do
      case v
      when String
        return v == 'true' ? 1 : 0
      else
        return v == true ? 1 : 0
      end
    end

    def to_s
      self.answer_id.to_s
    end

    def <=>(other)
      self.answer_id <=> other.answer_id
    end
  end

  class SurveyQuestion < Base
    property :survey_id
    property :question_id, required: true
    property :heading, required: true
    property :position, required: true
    property :family_type, from: :type, with: lambda { |type| type.fetch('family', '') }, required: true
    property :subtype, from: :type, with: lambda { |type| type.fetch('subtype', '') }, required: true
    property :answers, required: true

    coerce_key :answers, Array[MonkeyBusiness::ResponseOption]

    def to_s
      self.question_id.to_s
    end

    def <=>(other)
      self.question_id <=> other.question_id
    end
  end

  class Respondent < Base
    property :respondent_id, required: true
    property :date_start
    property :date_modified
    property :custom_id

    def to_s
      sprintf("%s (%s)", self.respondent_id, self.custom_id)
    end

    def <=>(other)
      self.respondent_id <=> other.respondent_id
    end

    def initialize(attributes = {}, &block)
      begin
        super(attributes, &block)

        @log = Logging.logger[self]
        @log.level = :warn

      rescue StandardError => e
        raise e
      end
    end
  end

  class Respondents < Base
    property :respondents, required: true
    property :survey, resuired: true

    coerce_key :respondents, Array[MonkeyBusiness::Respondent]
    coerce_key :survey, MonkeyBusiness::Survey

    def initialize(attributes = {}, &block)
      begin
        super(attributes, &block)

        @log = Logging.logger[self]
        @log.level = :debug

      rescue StandardError => e
        raise e
      end
    end

    def to_s
      sprintf("%s respondents", self.survey_id.to_s)
    end

    def <=>(other)
      self.survey <=> other.survey
    end
  end

  class ResponseAnswer < Base
    property :response_row, required: true, from: :row
    property :response_col, default: '', from: :col
    property :response_col_choice, default: '', from: :col_choice
    property :response_text, default: '', from: :text

    property :respondent

    coerce_key :respondent, MonkeyBusiness::Respondent

    def to_s
      self.response_row.to_s
    end

    def <=>(other)
      self.response_row <=> other.response_row
    end
  end

  class Response < Base
    property :question_id, required: true
    property :answers, default: []

    coerce_key :answers, Array[MonkeyBusiness::ResponseAnswer]

    def to_s
      self.question_id.to_s
    end

    def <=>(other)
      self.question_id <=> other.question_id
    end
  end

  class Responses < Base
    property :respondent_id, required: true
    property :questions, default: []

    coerce_key :questions, Array[MonkeyBusiness::Response]

    def to_s
      self.respondent_id.to_s
    end

    def <=>(other)
      self.respondent_id <=> other.respondent_id
    end
  end

  class Row < Base
    def written?
      self.written ? true : false
    end

    def field_values(fields = self.fields)
      begin
        fields.collect { |field| self.send(field.to_sym) }.collect { |field| field.nil? ? '' : field }

      rescue StandardError => e
        raise e
      end
    end

    def self.default_fields
      self.const_get(:Fields) || []
    end

    def self.default_outfile
      self.const_get(:Outfile) || ''
    end

    def self.default_table
      self.const_get(:Table) || ''
    end

    def self.default_s3_prefix
      ''
    end

    def self.default_s3_bucket
      MonkeyBusiness::MonkeyAWS::S3_Bucket.to_s || ''
    end

    def self.default_aws_region
      MonkeyBusiness::MonkeyAWS::Aws_Region.to_s || ''
    end

    def self.default_db_connection
      MonkeyBusiness::MonkeySQL::Db_Connection.to_s || ''
    end

    def self.to_csv(field_values = [])
      begin
        CSV.generate do |csv|
          csv << field_values
        end

      rescue StandardError => e
        raise e
      end
    end

    def self.headers(fields = default_fields)
      begin
        self.to_csv(fields)

      rescue StandardError => e
        raise e
      end
    end

    def self.write!(csv = self.to_csv, outfile = self.outfile, clobber = false)
      begin
        filemode = clobber ? 'w' : 'a'

        File.open(outfile, mode = filemode) do |csvfile|
          csvfile << csv
        end

        outfile

      rescue StandardError => e
        raise e
      end
    end

    def write(csv = self.class.to_csv(self.field_values), outfile = self.outfile, clobber = false)
      begin

        if self.written?
          return true
        else
          self.class.write!(csv, outfile, clobber)
          self.written = true

        end

      rescue StandardError => e
        raise e
      end
    end

    def self.upload(prefix = (self.s3_prefix || ''), outfile = self.default_outfile, bucket = self.default_s3_bucket, region = self.default_aws_region)
      begin
        @log = Logging.logger[self]

        basename = File.basename(outfile)
        key = File.join(prefix, basename).concat('.gz')

        # make a gzipped stream and upload to S3
        File.open(outfile, 'r') do |file|
          s3 = Aws::S3::Client.new(:raise_response_errors => true, :region => region)

          StringIO.open('', 'w') do |strio|
            gz = Zlib::GzipWriter.new(strio)

            file.each {|line| gz.write(line)}

            gz.close

            s3.put_object(:bucket => bucket, :key => key, :body => strio.string)

          end
        end

      rescue StandardError => e
        raise e
      end
    end

    def self.dbimport(survey_id, prefix = self.default_s3_prefix, db_params = {}, clobber = true, outfile = self.default_outfile, bucket = self.default_s3_bucket, region = self.default_aws_region)
      begin
        @log = Logging.logger[self]

        db = MonkeyBusiness::MonkeySQL::DBClient.new(db_params)

        key = sprintf("%s/%s.gz", prefix, File.basename(outfile))

        db.import_from_s3(self, survey_id, bucket, key, clobber)

      rescue StandardError => e
        binding.pry
        raise e
      end
    end

    def self.to_s
      self.to_csv.chomp
    end

    def initialize(attributes = {}, &block)
      super(attributes, &block)

      @log = Logging.logger[self]
    end

    property :fields, required: true, default: []
    property :outfile, required: true
    property :written, default: nil
    property :table, default: nil
    property :aws_region, required: true, default: self.default_aws_region
    property :s3_bucket, required: true, default: self.default_s3_bucket
    property :s3_prefix, required: true, default: ''

  end

  class SurveyRow < Row
    Fields = [
      'survey_id',
      'language_id',
      'nickname',
      'title',
    ]

    Outfile = File.join('.', 'tmp', 'survey.csv')

    Table = 'survey'

    property :fields, default: Fields
    property :outfile, default: Outfile
    property :survey_id, required: true
    property :language_id, required: true
    property :nickname, required: true
    property :title, from: :title_text

    def initialize(survey, &block)
      begin
        super(survey, &block)

        @log = Logging.logger[self]

      rescue StandardError => e
        raise e
      end
    end
  end

  class SurveyQuestionRow < Row
    Fields = [
      'survey_id',
      'question_id',
      'heading',
      'position',
      'family_type',
      'subtype',
      'custom_variable_label',
    ]

    Outfile = File.join('.', 'tmp', 'survey_question.csv')

    Table = 'survey_question'

    property :fields, default: Fields
    property :outfile, default: Outfile
    property :question_id, required: true
    property :heading, required: true
    property :position, required: true
    property :family_type, required: true
    property :subtype, required: true

    property :survey_id
    property :custom_variable_label

    def initialize(question = {}, survey = {}, &block)
      begin
        super(question, &block)

        @log = Logging.logger[self]

        # get the survey_id from the survey
        self.survey_id = survey.survey_id

        # get the custom_variable_label from the survey
        cvars = {}
        survey.custom_variables.each do |cvar|
          cvars.store(cvar.fetch('question_id'), cvar.fetch('variable_label'))
        end
        self.custom_variable_label=cvars.fetch(self.question_id, '')

      rescue StandardError => e
        raise e
      end
    end

  end

  class SurveyResponseOptionRow < Row
    Fields = [
      'question_id',
      'response_option_id',
      'position',
      'text',
      'type',
      'visible',
    ]

    Outfile = File.join('.', 'tmp', 'survey_response_option.csv')

    Table = 'survey_response_option'

    property :fields, default: Fields
    property :outfile, default: Outfile
    property :response_option_id, required: true, from: :answer_id
    property :position, required: true
    property :text, required: true
    property :type, required: true
    property :visible, required: true

    property :question_id

    def initialize(response_option = {}, question = {}, &block)
      begin
        super(response_option, &block)

        @log = Logging.logger[self]

        # get the question_id from the question
        self.question_id = question.question_id

      rescue StandardError => e
        raise e
      end
    end

    def to_s
      self.response_option_id.to_s
    end
  end

  class SurveyResponseRow < Row
    # storing complicated lambdas in variables for readability
    sanitize_freeform_text = lambda do |freeform_text|
      # clean up whitespace, line breaks, double quotes
      freeform_text.to_s.split(/\s+/).join(' ').gsub('"', '').strip
    end

    Fields = [
      'survey_id',
      'question_id',
      'response_col',
      'response_row',
      'response_text',
      'userid',
      'custom_id',
      'response_time',
    ]

    Outfile = File.join('.', 'tmp', 'survey_response.csv')

    Table = 'survey_response'

    property :fields, default: Fields
    property :outfile, default: Outfile
    property :response_col, required: true
    property :response_row, required: true
    property :response_text, required: true, transform_with: sanitize_freeform_text

    property :survey_id
    property :question_id
    property :userid
    property :custom_id
    property :response_time

    def initialize(response_answer = {}, survey = {}, question = {}, respondent = {}, &block)
      begin
        super(response_answer, &block)

        @log = Logging.logger[self]

        # get a whole bunch of stuff from other places
        self.survey_id = survey.survey_id

        self.question_id = question

        self.userid = respondent.respondent_id

        self.custom_id = respondent.custom_id

        newest_date = respondent.date_modified ? respondent.date_modified : respondent.date_start
        self.response_time = newest_date

      rescue StandardError => e
        raise e
      end
    end
  end

end
