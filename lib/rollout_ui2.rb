require "rollout_ui2/version"
require 'sinatra/base'
require 'rollout'
require 'yaml'

module RolloutUi2
  class << self
    def wrap(rollout)
      @rollout = rollout
    end

    def store
      @store ||= begin
        require 'redis'
        Redis.new
      end
    end

    def rollout
      @rollout ||= Rollout.new(store)
    end

    def index
      rollout.features.empty? ? [] : multi(rollout.features.sort)
    end

    def get(name)
      rollout.get(name)
    end

    def save(feature)
      rollout.send(:save, feature)
    end

    def delete(feature)
      rollout.delete(feature.name)
    end

    private

    def multi(keys)
      features = if rollout.respond_to?(:multi_get)
                   rollout.multi_get(*keys)
                 else
                   keys.map { |key| get(key) }
                 end
      features.map { |f| Feature.new(f) }
    end
  end

  class Feature < SimpleDelegator
    alias feature __getobj__

    def data
      CGI::escapeHTML(feature.data.to_yaml.sub(/\A---\s/, '')) if data?
    end

    def data?
      feature.respond_to?(:data)
    end
  end

  class Server < Sinatra::Base
    helpers do
      def all_groups(features)
        features.reduce([]) { |a, e| a | e.groups }
      end

      def as_array(param)
        param.respond_to?(:split) ? param.split(",") : param || []
      end

      def url_path(*path_parts)
        [ path_prefix, path_parts ].join("/").squeeze('/')
      end
      alias_method :u, :url_path

      def path_prefix
        request.env['SCRIPT_NAME']
      end

      def public?(feature)
        feature.percentage >= 100
      end

      def hidden?(feature)
        feature.percentage <= 0 && feature.groups == [] && feature.users == []
      end

      def icon(feature)
        return "eye-close" if hidden?(feature)
        return "eye-open" if public?(feature)
        "filter"
      end
    end

    get '/' do
      @features = RolloutUi2.index
      @groups = all_groups(@features)
      erb :index
    end

    post '/' do
      feature = RolloutUi2.get(params["name"])

      case params["action"]
      when "new"
        RolloutUi2.save(feature)
      when "delete"
        RolloutUi2.delete(feature)
      when "update"
        feature.percentage = params["percentage"].to_f
        feature.groups = as_array(params["groups"])
        feature.users = as_array(params["users"])

        RolloutUi2.save(feature)
      end

      redirect to('/')
    end
  end
end
