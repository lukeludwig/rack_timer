module ActionDispatch
  class MiddlewareStack < Array

    # this class will wrap around each Rack-based middleware and take timing snapshots of how long
    # each middleware takes to execute
    class RackTimer

      LogThreshold = ENV.has_key?('RACK_TIMER_LOG_THRESHOLD') ? ENV['RACK_TIMER_LOG_THRESHOLD'].to_f : 1.0 # millisecond

      def initialize(app)
        @app = app
      end

      def call(env)
        if env.has_key?("MIDDLEWARE_TIMESTAMP") # skip over the first middleware
          elapsed_time = (Time.now.to_f - env["MIDDLEWARE_TIMESTAMP"][1].to_f) * 1000 
          if elapsed_time > LogThreshold # only log if took greater than LogThreshold
            Rails.logger.info "Rack Timer -- #{env["MIDDLEWARE_TIMESTAMP"][0]}: #{elapsed_time} ms"
          end
        elsif env.has_key?("HTTP_X_REQUEST_START")
          # if we are tracking request queuing time via New Relic's suggested header,
          # then lets see how much time was spent in the request queue by taking the difference
          # between Time.now from the start of the first piece of middleware
          queue_start_time = env["HTTP_X_REQUEST_START"].gsub("t=", "").to_i
          Rails.logger.info "Rack Timer -- Queuing time: #{(Time.now.to_f * 1000000).to_i - queue_start_time} microseconds"
        end
        env["MIDDLEWARE_TIMESTAMP"] = [@app.class.to_s, Time.now]
        @app.call env
      end

    end

    class Middleware

      # overrding the built-in Middleware.build and adding a RackTimer wrapper class
      def build(app)
        RackTimer.new(klass.new(app, *args, &block))
      end    

    end
    
  end
end