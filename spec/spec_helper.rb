begin
  require 'coveralls'
  Coveralls.wear!
rescue LoadError => _e
  'coveralls is optional'
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rollout_ui2'
require 'rollout'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

RSpec.configure { |c| c.include Rack::Test::Methods }

class Store < SimpleDelegator
  def initialize
    super({})
  end

  def set(key, value)
    self[key] = value
  end

  def get(key)
    self[key]
  end

  def mget(*keys)
    keys.map { |key| self[key] }
  end

  def del(key)
    delete(key)
  end
end
