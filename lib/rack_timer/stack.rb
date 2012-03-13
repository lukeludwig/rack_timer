module ActionDispatch
  class MiddlewareStack < Array

    # this class will wrap around each Rack-based middleware and take timing snapshots of how long
    # each middleware takes to execute
    class RackTimer

      # modify this environment variable to see more or less output
      LogThreshold = ENV.has_key?('RACK_TIMER_LOG_THRESHOLD') ? ENV['RACK_TIMER_LOG_THRESHOLD'].to_f : 1.0 # millisecond

      def initialize(app)
        @app = app
      end

      def call(env)
        env = incoming_timestamp(env)
        status, headers, body = @app.call env
        env = outgoing_timestamp(env)
        [status, headers, body]
      end

      def incoming_timestamp(env)
        if env.has_key?("MIDDLEWARE_TIMESTAMP") # skip over the first middleware
          elapsed_time = (Time.now.to_f - env["MIDDLEWARE_TIMESTAMP"][1].to_f) * 1000 
          if elapsed_time > LogThreshold # only log if took greater than LogThreshold
            Rails.logger.info "Rack Timer (incoming) -- #{env["MIDDLEWARE_TIMESTAMP"][0]}: #{elapsed_time} ms"
          end
        elsif env.has_key?("HTTP_X_REQUEST_START") or env.has_key?("HTTP_X_QUEUE_START")
          # if we are tracking request queuing time via New Relic's suggested header(s),
          # then lets see how much time was spent in the request queue by taking the difference
          # between Time.now from the start of the first piece of middleware
          # prefer HTTP_X_QUEUE_START over HTTP_X_REQUEST_START in case both exist
          queue_start_time = (env["HTTP_X_QUEUE_START"] || env["HTTP_X_REQUEST_START"]).gsub("t=", "").to_i
          Rails.logger.info "Rack Timer -- Queuing time: #{(Time.now.to_f * 1000000).to_i - queue_start_time} microseconds"
        end
        env["MIDDLEWARE_TIMESTAMP"] = [@app.class.to_s, Time.now]
        env
      end

      def outgoing_timestamp(env)
        if env.has_key?("MIDDLEWARE_TIMESTAMP")
          elapsed_time = (Time.now.to_f - env["MIDDLEWARE_TIMESTAMP"][1].to_f) * 1000
          if elapsed_time > LogThreshold # only log if took greater than LogThreshold
            if env["MIDDLEWARE_TIMESTAMP"][0] and env["MIDDLEWARE_TIMESTAMP"][0] == @app.class.to_s
              # this is the actual elapsed time of the final piece of Middleware (typically routing) AND the actual
              # application's action
              Rails.logger.info "Rack Timer (Application Action) -- #{@app.class.to_s}: #{elapsed_time} ms"              
            else
              Rails.logger.info "Rack Timer (outgoing) -- #{@app.class.to_s}: #{elapsed_time} ms"
            end
          end
        end
        env["MIDDLEWARE_TIMESTAMP"] = [nil, Time.now]
        env
      end

    end

    class Middleware

      # overrding the built-in Middleware.build and adding a RackTimer wrapper class
      def build(app)
        RackTimer.new(klass.new(app, *args, &block))
      end    

    end

    # overriding this in order to wrap the incoming app in a RackTimer, which gives us timing on the final
    # piece of Middleware, which for Rails is the routing plus the actual Application action
    def build(app = nil, &block)
      app ||= block
      raise "MiddlewareStack#build requires an app" unless app
      reverse.inject(RackTimer.new(app)) { |a, e| e.build(a) }
    end

  end
end