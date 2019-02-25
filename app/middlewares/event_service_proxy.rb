class EventServiceProxy < Rack::Proxy
  def initialize(app)
    @app = app
  end

  def call(env)
    original_host = env["HTTP_HOST"]
    rewrite_env(env)
    if env["HTTP_HOST"] != original_host
      perform_request(env)
    else
      @app.call(env)
    end
  end

  def rewrite_env(env)
    request = Rack::Request.new(env)
    if request.path.match('/events') && env['warden'].authenticated?
      env["HTTP_HOST"] = "localhost:8000"
    end
    env
  end
end
