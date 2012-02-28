module ActionDispatch
  class MiddlewareStack < Array

    # this will wrap around each Rack-based middleware and take timing snapshots of how long
    # each middleware takes to execute
    class RackTimer

      LogThreshold = 1.0 # millisecond

      def initialize(app)
        @app = app
      end

      def call(env)
        # skip over the first middleware
        if env.has_key?("MIDDLEWARE_TIMESTAMP")
          time_taken = (Time.now.to_f - env["MIDDLEWARE_TIMESTAMP"][1].to_f) * 1000 
          if time_taken > LogThreshold # only log if took greater than 1 ms
            Rails.logger.info "Rack Timer -- #{env["MIDDLEWARE_TIMESTAMP"][0]}: #{time_taken} ms"
          end
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