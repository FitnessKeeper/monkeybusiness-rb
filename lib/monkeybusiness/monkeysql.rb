require 'monkeybusiness/monkeylogging'

module MonkeyBusiness

  include MonkeyBusiness::MonkeyLogging

  module MonkeySQL
    # constants
    Queries = {
      'MonkeyBusiness::SurveyQuestionRow' => {
        'copy' => 'COPY survey_question (survey_id, question_id, heading, position, family_type, subtype) FROM ? CREDENTIALS ? DELIMITER ? MAXERROR 100 GZIP REMOVEQUOTES IGNOREHEADER 1 TIMEFORMAT ?',
        'delete' => 'DELETE FROM survey_question WHERE survey_id = ?',
      },
      'MonkeyBusiness::SurveyResponseOptionRow' => {
        'copy' => 'COPY survey_response_option (question_id, response_option_id, position, text, type, visible) FROM ? CREDENTIALS ? DELIMITER ? MAXERROR 1 GZIP REMOVEQUOTES IGNOREHEADER 1 TIMEFORMAT ?',
        'delete' => 'DELETE FROM survey_response_option WHERE question_id = :question_id',
      },
      'MonkeyBusiness::SurveyResponseRow' => {
        'copy' => 'COPY survey_response (survey_id, question_id, response_col, response_row, response_text, userid, custom_id, response_time) FROM ? CREDENTIALS ? DELIMITER ? MAXERROR 1 GZIP REMOVEQUOTES IGNOREHEADER 1 TIMEFORMAT ?',
        'delete' => 'DELETE FROM survey_response WHERE survey_id = ?',
      },
      'MonkeyBusiness::SurveyRow' => {
        'copy' => 'COPY survey (survey_id, language_id, nickname, title) FROM ? CREDENTIALS ? DELIMITER ? MAXERROR 1 GZIP REMOVEQUOTES IGNOREHEADER 1 TIMEFORMAT ?',
        'delete' => 'DELETE FROM survey WHERE survey_id = ?',
      }
    }

    Access_Key = ENV.fetch('SURVEYMONKEY_ACCESS_KEY', '')
    Secret_Key = ENV.fetch('SURVEYMONKEY_SECRET_KEY', '')

    Default_Delimiter = ','
    Default_Timeformat = 'YYYY-MM-DD HH:MI:SS'

    Driver = ENV.fetch('REDSHIFT_DRIVER', 'postgres')
    Host   = ENV.fetch('REDSHIFT_HOST', 'localhost')
    Port   = ENV.fetch('REDSHIFT_PORT', '5489')
    User   = ENV.fetch('REDSHIFT_USER', '')
    Pass   = ENV.fetch('REDSHIFT_PASS', '')
    DB     = ENV.fetch('REDSHIFT_DB', '')

    class DBClient
      attr_accessor :connection_string, :connection_params, :sequel

      def import_from_s3(target, survey_id, bucket, key, clobber = true, access_key = MonkeyBusiness::MonkeySQL::Access_Key, secret_key = MonkeyBusiness::MonkeySQL::Secret_Key, queries = MonkeyBusiness::MonkeySQL::Queries)
        begin
          target_name = target.name


          s3_path = build_s3_path(bucket, key)

          credentials = build_credentials(access_key, secret_key)

          delimiter = build_delimiter

          timeformat = build_timeformat

          copy_query = queries[target_name]['copy']
          delete_query = queries[target_name]['delete']

          table = target.default_table

          if clobber
            self.sequel.transaction do
              ds = self.sequel[delete_query, survey_id].delete
            end
          end

          self.sequel.fetch(copy_query, s3_path, credentials, delimiter, timeformat).all

        rescue Sequel::DatabaseError => e
          if e.wrapped_exception.message == 'No results were returned by the query.'
            # it's OK for the COPY command to return no results
          else
            raise e
          end

        rescue KeyError => e
          raise e

        rescue StandardError => e
          raise e

        end
      end

      private

      def build_s3_path(bucket, key)
        s3_path = sprintf("s3://%s/%s", bucket, key)

        s3_path
      end

      def build_credentials(access_key, secret_key)
        credentials = sprintf("aws_access_key_id=%s;aws_secret_access_key=%s", access_key, secret_key)

        credentials
      end

      def build_delimiter(delimiter = MonkeySQL::Default_Delimiter)
        delimiter.to_s
      end

      def build_timeformat(timeformat = MonkeySQL::Default_Timeformat)
        timeformat.to_s
      end

      def build_connection_string(driver = MonkeySQL::Driver, host = MonkeySQL::Host, port = MonkeySQL::Port, user = MonkeySQL::User, pass = MonkeySQL::Pass, db = MonkeySQL::DB)
        begin
          connection_string = sprintf("%s://%s:%s/%s?user=%s&password=%s", driver, host, port, db, user, pass)

          if driver =~ /^jdbc:postgres/
            connection_string.concat('&ssl=true&sslfactory=org.postgresql.ssl.NonValidatingFactory')
          else
            connection_string
          end

        rescue StandardError => e
          raise e
        end
      end

      def initialize(connection_params = {}, connection_string = build_connection_string)
        begin
          @log = Logging.logger[self]
          @connection_string = connection_string

          default_params = {
            loggers: [@log],
            sslmode: 'require',
            client_min_messages: false,
            force_standard_strings: false,
          }

          merged_params = default_params.merge(connection_params)

          @connection_params = merged_params

          @sequel = Sequel.connect(connection_string, merged_params)

        rescue StandardError => e
          raise e
        end
      end
    end
  end
end
