module MonkeyBusiness
  module MonkeyAWS
    # constants
    Aws_Region = 'us-east-1'
    S3_Bucket = 'sessionsense-exports'

    Boto_Config = <<-BOTO.gsub(/^\s+/, '')
    [Credentials]
    aws_access_key_id = <%= access_key %>
    aws_secret_access_key = <%= secret_key %>
    BOTO

    def self.genconfig(access_key = ENV['SURVEYMONKEY_ACCESS_KEY'], secret_key = ENV['SURVEYMONKEY_SECRET_KEY'])
      begin
        config = ERB.new(MonkeyBusiness::MonkeyAWS::Boto_Config).result

        configfile = File.join(ENV['HOME'], '.boto')

        unless File.exist?(configfile)
          File.open(configfile, 'w') do |cf|
            cf << config
          end
        end

      rescue StandardError => e
        raise e
      end
    end

    class S3Client < Aws::S3::Client
    end
  end
end
