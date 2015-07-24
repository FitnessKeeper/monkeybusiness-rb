require 'sidekiq'
require 'json'
require 'monkeybusiness'

module MonkeyBusiness
  class APIWorker
    include Sidekiq::Worker
    sidekiq_options :retry => 1

    def perform(method, params)
      begin
        return if cancelled?

        logger.debug(sprintf('%s: performing %s (%s)', __method__, method, params.inspect))
        result = MonkeyBusiness.send(method.to_sym, params)

        # save the result
        resultkey = "result-#{jid}"
        logger.debug(sprintf('%s: saving %s to %s', __method__, method, resultkey))
        Sidekiq.redis {|c| c.set(resultkey, result.to_json) }

      rescue StandardError => e
        logger.error(sprintf('%s: %s', __method__, e.message))
        raise e
      end
    end

    def cancelled?
      Sidekiq.redis {|c| c.exists("cancelled-#{jid}") }
    end

    def cancel!
      Sidekiq.redis {|c| c.setex("cancelled-#{jid}", 86400, 1) }
    end
  end
end
