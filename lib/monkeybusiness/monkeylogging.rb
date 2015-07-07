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
      Logging.appenders.syslog('SYSLOG',
                               :ident => 'monkeybusiness',
                               :level => :info
                              )

      Logging.logger.root.level = :debug
      Logging.logger.root.add_appenders(
        'STDERR',
        'SYSLOG'
      )

      # did we get a logfile from the environment?
      monkeybusiness_logfile = ENV['MONKEYBUSINESS_LOGFILE']

      unless monkeybusiness_logfile.nil?
        Logging.appenders.file('LOGFILE',
                               :filename => monkeybusiness_logfile,
                               :level    => :debug
                              )

        Logging.logger.root.add_appenders('LOGFILE')
      end

      # set per-class logging
      Logging.logger['MonkeyBusiness::SurveyRow'].level               = :debug
      Logging.logger['MonkeyBusiness::SurveyQuestionRow'].level       = :debug
      Logging.logger['MonkeyBusiness::SurveyResponseOptionRow'].level = :debug
      Logging.logger['MonkeyBusiness::SurveyResponseRow'].level       = :debug
      Logging.logger['MonkeyBusiness::MonkeyAWS::S3Client'].level     = :debug
      Logging.logger['MonkeyBusiness::MonkeySQL::DBClient'].level     = :debug

    rescue StandardError => e
      puts "unable to configure logging: #{e.message}"
      raise e
    end
  end
end
