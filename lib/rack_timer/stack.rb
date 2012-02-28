module ActionDispatch
  class MiddlewareStack < Array

    # this will wrap around each Rack-based middleware and take timing snapshots of how long
    # each middleware takes to execute
    class RackTimer

      def initialize(app)
        @app = app
      end

      def call(env)
        # skip over the first middleware
        if env.has_key?("MIDDLEWARE_TIMESTAMP")
          Rails.logger.info ">>>>>> #{env["MIDDLEWARE_TIMESTAMP"][0]}: #{(Time.now.to_f - env["MIDDLEWARE_TIMESTAMP"][1].to_f) * 1000} ms"
          env["MIDDLEWARE_TIMESTAMP"][1]
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