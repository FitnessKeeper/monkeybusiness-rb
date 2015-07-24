# shenanigans
require "dotenv"
Dotenv.load

# add /usr/src/app to $LOAD_PATH
loaddirs = [
  ['/usr', 'src', 'app', 'lib'],
  ['.', 'lib'],
]

loaddirs.each do |path|
  libdir = File.join(path)
  $LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
end

require 'sidekiq'
require 'sidekiq/api'

require "monkeybusiness"
require 'monkeybusiness/monkeylogging'
require 'monkeybusiness/apiworker'

module MonkeyBusiness
  class Scheduler

    include MonkeyBusiness::MonkeyLogging

    # Sidekiq
    Sidekiq.configure_server do |config|
      config.redis = {
        :namespace => 'monkeybusiness',
      }
    end

    Sidekiq::Logging.logger = Logging.logger[self]

  end
end
