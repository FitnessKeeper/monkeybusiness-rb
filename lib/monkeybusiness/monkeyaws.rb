module MonkeyBusiness
  module MonkeyAWS
    # constants
    Aws_Region = 'us-east-1'
    S3_Bucket = 'sessionsense-exports'

    class S3Client < Aws::S3::Client

    end
  end
end
