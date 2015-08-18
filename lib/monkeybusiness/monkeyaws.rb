require 'monkeybusiness/monkeylogging'

module MonkeyBusiness
  module MonkeyAWS
    include MonkeyBusiness::MonkeyLogging

    # constants
    Aws_Region = 'us-east-1'
    S3_Bucket = 'sessionsense-exports'

    def self.genconfig(access_key = ENV['SURVEYMONKEY_ACCESS_KEY'], secret_key = ENV['SURVEYMONKEY_SECRET_KEY'])
      begin
        @log = Logging.logger[self]

        @log.debug(sprintf('%s: access_key: %s, secret_key: %s', __method__, access_key, secret_key))

        boto_config = <<-BOTO.gsub(/^\s+/, '')
        [Credentials]
        aws_access_key_id = <%= access_key %>
        aws_secret_access_key = <%= secret_key %>

        BOTO
        config = ERB.new(boto_config).result

        configfile = File.join(ENV['HOME'], '.boto')

        unless File.exist?(configfile)
          File.open(configfile, 'w') do |cf|
            cf << config
          end
        end

      rescue StandardError => e
        @log.error(sprintf('%s: %s', __method__, e.message))
        raise e
      end
    end

    class S3Client < Aws::S3::Client
    end
  end
end
