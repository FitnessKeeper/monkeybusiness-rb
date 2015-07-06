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

      Logging.logger.root.level = :error
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
      Logging.logger['MonkeyBusiness::SurveyRow'].level               = :info
      Logging.logger['MonkeyBusiness::SurveyQuestionRow'].level       = :info
      Logging.logger['MonkeyBusiness::SurveyResponseOptionRow'].level = :info
      Logging.logger['MonkeyBusiness::SurveyResponseRow'].level       = :info
      Logging.logger['MonkeyBusiness::MonkeyAWS::S3Client'].level     = :info
      Logging.logger['MonkeyBusiness::MonkeySQL::DBClient'].level     = :info

    rescue StandardError => e
      puts "unable to configure logging: #{e.message}"
      raise e
    end
  end
end
