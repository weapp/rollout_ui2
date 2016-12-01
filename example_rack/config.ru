require 'rollout_ui2'

require 'redis'
RolloutUi2.wrap(Rollout.new(Redis.new))

RolloutUi2::Server.use Rack::Auth::Basic do |user, pass|
  user == pass
end

run Rack::URLMap.new(
  # "/" => Your::App.new,
  "/rollout" => RolloutUi2::Server
)
