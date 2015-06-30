module MonkeyBusiness
  module MonkeyLogging
    begin
      # configure logging
      Logging.color_scheme( 'bright',
        :levels => {
          :debug => :gray,
          :info  => :green,
          :warn  => :yellow,
          :error => :red,
          :fatal => [:white, :on_red]
        },
        :date    => :blue,
        :logger  => :cyan,
        :message => :magenta
      )

      Logging.appenders.stderr('STDERR',
                               :level        => :warn,
                               :color_scheme => 'bright'
                              )
      Logging.appenders.file('LOGFILE',
                             :filename => File.join('tmp', 'monkeybusiness.log'),
                             :level    => :debug
                            )

      Logging.logger.root.level = :error
      Logging.logger.root.add_appenders(
        'STDERR',
        'LOGFILE'
      )

      # set per-class logging
      Logging.logger['MonkeyBusiness::SurveyRow'].level               = :warn
      Logging.logger['MonkeyBusiness::SurveyQuestionRow'].level       = :warn
      Logging.logger['MonkeyBusiness::SurveyResponseOptionRow'].level = :warn
      Logging.logger['MonkeyBusiness::SurveyResponseRow'].level       = :warn
      Logging.logger['MonkeyBusiness::MonkeyAWS::S3Client'].level     = :debug
      Logging.logger['MonkeyBusiness::MonkeySQL::DBClient'].level     = :debug

    rescue StandardError => e
      puts "unable to configure logging: #{e.message}"
      raise e
    end
  end
end
