# RolloutUi2

Rollout UI for Rollout 2!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rollout_ui2'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rollout_ui2


## Usage

Edit `config.ru` and add this:

```ruby
# config.ru

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
```

Execute `rackup` or `rails s` if you are using Rails

Visit `http://user:user@localhost:9292/rollout`

![screehshot](http://i.imgur.com/gQLOmAD.png)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/weapp/rollout_ui2.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
