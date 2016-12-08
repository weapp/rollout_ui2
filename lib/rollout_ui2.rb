require "rollout_ui2/version"
require 'sinatra/base'
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
      @rollout ||= begin
        require 'rollout'
        Rollout.new(store)
      end
    end

    def index
      rollout.features.empty? ? [] : multi(rollout.features.sort)
    end

    def get(name)
      Feature.new(rollout.get(name))
    end

    def save(feature)
      rollout.send(:save, feature)
    end

    def delete(feature)
      return rollout.delete(feature.name) if rollout.respond_to?(:delete)
      rollout.deactivate(feature.name)
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

    def groups
      feature.groups.to_a
    end

    def users
      feature.users.to_a
    end
  end

  class Server < Sinatra::Base
    helpers do
      def active_for(feature, key, user)
        return unless user && user != ""
        case key
        when :any
          feature.active?(RolloutUi2.rollout, user)
        when :percentage
          feature.feature.send(:user_in_percentage?, user) rescue nil
        when :user
          feature.feature.send(:user_in_active_users?, user) rescue nil
        when :group
          feature.feature.send(:user_in_active_group?, user, RolloutUi2.rollout) rescue nil
        end && yield || nil
      end

      def user
        params[:user]
      end

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

      redirect to("#{request.path_info}?#{request.query_string}")
    end
  end
end
