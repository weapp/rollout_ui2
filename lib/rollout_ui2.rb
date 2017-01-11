require "rollout_ui2/version"
require 'sinatra/base'
require 'yaml'

module RolloutUi2
  class << self
    attr_reader :rollouts
    attr_reader :finderss

    def with_finder(finder, key: :default)
      @finders ||= { default: finder }
      @finders[key] = finder
      self
    end

    def wrap(rollout, key: :default, finder: nil)
      @rollouts ||= { default: rollout }
      @rollouts[key] = rollout
      with_finder(finder, key: key) if finder
      self
    end

    def rollout(key = :default)
      @rollouts[key]
    end

    def finder(key = :default)
      @finders[key] if @finders
    end

    def index(key = :default)
      rollout(key).features.empty? ? [] : multi(rollout(key).features.sort, rollout(key))
    end

    def get(name, key = :default)
      Feature.new(rollout(key).get(name))
    end

    def save(feature, key = :default)
      rollout(key).send(:save, feature)
    end

    def delete(feature, key = :default)
      return rollout(key).delete(feature.name) if rollout(key).respond_to?(:delete)
      rollout(key).deactivate(feature.name)
    end

    def keys
      @rollouts.keys.reject { |i| i == :default}
    end

    private

    def multi(keys, rollout)
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
          feature.active?(current_rollout, current_user)
        when :percentage
          feature.feature.send(:user_in_percentage?, user) rescue nil
        when :user
          feature.feature.send(:user_in_active_users?, user) rescue nil
        when :group
          feature.feature.send(:user_in_active_group?, current_user, current_rollout) rescue nil
        end && yield || nil
      end

      def user
        params[:user]
      end

      def current_user
        @_current_user ||= if users_provided?
                             current_finder.find(user)
                           else
                             user
                           end
      end

      def current_key
        (params[:key] || :default).to_sym
      end

      def current_rollout
        RolloutUi2.rollout(current_key)
      end

      def current_finder
        RolloutUi2.finder(current_key)
      end

      def all_groups(features)
        defined_groups = current_rollout.instance_eval("@groups").keys rescue []
        defined_groups | features.reduce([]) { |a, e| a | e.groups }
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

      def users_2_select2(users)
        return users unless users_provided?
        current_finder
          .find_by_ids(Array(users))
          .map { |it| it.merge!(selected: true, placeholder: it[:text]) }
          .to_json
      end

      def users_provided?
        !current_finder.nil?
      end
    end

    get '/users' do
      return status 404 unless users_provided?
      current_finder
        .search(params["q"], (params["page"] || 1).to_i)
        .to_json
    end

    get '/' do
      @features = RolloutUi2.index(current_key)
      @groups = all_groups(@features)
      erb :index
    end

    post '/' do
      feature = RolloutUi2.get(params["name"], current_key)

      case params["action"]
      when "new"
        RolloutUi2.save(feature, current_key)
      when "delete"
        RolloutUi2.delete(feature, current_key)
      when "update"
        feature.percentage = params["percentage"].to_f
        feature.groups = as_array(params["groups"])
        feature.users = as_array(params["users"])

        RolloutUi2.save(feature, current_key)
      end

      redirect to("#{request.path_info}?#{request.query_string}")
    end
  end
end
