# name: MediaBot
# about: Automatically replies to topics with movie and TV show information
# version: 0.1.0
# authors: michaeltieso
# url: https://github.com/michaeltieso/discourse-mediabot
# required_version: 2.8.0

module ::MediaBot
  PLUGIN_NAME = "mediabot"
  
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace MediaBot
  end
end

# Register settings
register_asset "stylesheets/mediabot.scss"

# Load required files
require_relative "lib/mediabot/fetcher"
require_relative "lib/mediabot/title_parser"
require_relative "lib/mediabot/reply_formatter"
require_relative "jobs/regular/mediabot_reply"
require_relative "jobs/regular/mediabot_inline_reply"

# Register event handlers
DiscourseEvent.on(:topic_created) do |topic, opts, user|
  if SiteSetting.mediabot_enabled
    Jobs.enqueue_in(
      SiteSetting.mediabot_reply_delay.seconds,
      :mediabot_reply,
      topic_id: topic.id
    )
  end
end

# Handle inline commands in posts
DiscourseEvent.on(:post_created) do |post, opts, user|
  if SiteSetting.mediabot_enabled && SiteSetting.mediabot_enable_inline_commands
    Jobs.enqueue_in(
      SiteSetting.mediabot_reply_delay.seconds,
      :mediabot_inline_reply,
      post_id: post.id
    )
  end
end

# Admin routes
add_admin_route 'mediabot.title', 'mediabot'

module ::Admin
  class MediaBotController < ::Admin::AdminController
    requires_plugin 'mediabot'
    
    def index
      render_json_dump(
        settings: {
          enabled: SiteSetting.mediabot_enabled,
          enabled_tags: SiteSetting.mediabot_enabled_tags,
          enabled_categories: SiteSetting.mediabot_enabled_categories,
          display_options: {
            show_title: SiteSetting.mediabot_show_title,
            show_poster: SiteSetting.mediabot_show_poster,
            show_overview: SiteSetting.mediabot_show_overview,
            show_cast: SiteSetting.mediabot_show_cast,
            show_rating: SiteSetting.mediabot_show_rating,
            show_genres: SiteSetting.mediabot_show_genres,
            show_runtime: SiteSetting.mediabot_show_runtime,
            show_links: SiteSetting.mediabot_show_external_links
          }
        },
        metrics: {
          tmdb: MediaBot::PerformanceMonitor.get_metrics('tmdb'),
          tvdb: MediaBot::PerformanceMonitor.get_metrics('tvdb')
        },
        errors: MediaBot::ErrorHandler.get_recent_errors(50)
      )
    end
    
    def update_settings
      params.require(:settings).permit(
        :enabled,
        :enabled_tags,
        :enabled_categories,
        display_options: [
          :show_title,
          :show_poster,
          :show_overview,
          :show_cast,
          :show_rating,
          :show_genres,
          :show_runtime,
          :show_links
        ]
      ).each do |key, value|
        if key == 'display_options'
          value.each do |option, enabled|
            SiteSetting.send("mediabot_#{option}=", enabled)
          end
        else
          SiteSetting.send("mediabot_#{key}=", value)
        end
      end
      
      render json: success_json
    end
    
    def clear_metrics
      MediaBot::PerformanceMonitor.clear_metrics
      render json: success_json
    end
    
    def clear_errors
      MediaBot::ErrorHandler.clear_errors
      render json: success_json
    end
    
    def test_api
      service = params[:service]
      title = params[:title]
      
      begin
        fetcher = MediaBot::Fetcher.new(service)
        result = fetcher.fetch(title)
        
        render json: {
          success: true,
          data: result
        }
      rescue StandardError => e
        render json: {
          success: false,
          error: MediaBot::ErrorHandler.handle_error(e, service: service, title: title)
        }, status: 422
      end
    end
  end
end

Discourse::Application.routes.append do
  mount ::MediaBot::Engine, at: "/mediabot"
  
  namespace :admin, constraints: StaffConstraint.new do
    get 'plugins/mediabot' => 'mediabot#index'
    put 'plugins/mediabot/settings' => 'mediabot#update_settings'
    post 'plugins/mediabot/clear_metrics' => 'mediabot#clear_metrics'
    post 'plugins/mediabot/clear_errors' => 'mediabot#clear_errors'
    post 'plugins/mediabot/test_api' => 'mediabot#test_api'
  end
end 