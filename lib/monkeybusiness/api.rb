require 'grape'
require 'json'
require 'sidekiq/client'
require 'sidekiq/api'

require "monkeybusiness"
require 'monkeybusiness/monkeylogging'
require 'monkeybusiness/apiworker'

module MonkeyBusiness
  class API < Grape::API

    include MonkeyBusiness::MonkeyLogging

    # Sidekiq
    Sidekiq.configure_client do |config|
      config.redis = {
        :namespace => 'monkeybusiness',
        :size => 1,
      }
    end

    # top-level API configuration
    format :json
    default_format :json

    helpers do
      def log
        API.logger
      end
    end

    post '/perform' do
      log.debug(sprintf('%s: params: %s', __method__, params.inspect))
      log.debug(sprintf('%s: enqueueing delayed job', __method__))

      method_name = params[:method]
      method_params = params[:params]

      Sidekiq::Client.enqueue(MonkeyBusiness::APIWorker, method_name, method_params)
    end

    get '/result/:jid' do
      begin
        jid = params[:jid]

        log.debug(sprintf('%s: querying jid %s', __method__, jid))

        result = Sidekiq.redis {|c| c.get("result-#{jid}") }

        if result.nil?
          log.debug(sprintf('%s: no result for jid %s', __method__, jid))

          ''
        else
          log.debug(sprintf('%s: result found for jid %s', __method__, jid))

          JSON.parse(result)
        end
      rescue StandardError => e
        log.error(sprintf('%s: %s', __method__, e.message))
        raise
      end
    end

    get '/queue' do
      queue = Sidekiq::Queue.new

      queue.inspect
    end

    get '/stats' do
      stats = Sidekiq::Stats.new

      stats.inspect
    end

  end
end
