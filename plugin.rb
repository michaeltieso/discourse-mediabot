# name: discourse-mediabot
# about: Automatically replies to topics and posts with movie and TV show information
# version: 0.1.0
# authors: Michael Tieso
# url: https://github.com/michaeltieso/discourse-mediabot
# required_version: 2.8.0

enabled_site_setting :mediabot_enabled

module ::DiscourseMediaBot
  PLUGIN_NAME = "discourse-mediabot"
end

require_relative "lib/mediabot/engine"

after_initialize do
  # Register event handlers
  on(:topic_created) do |topic, opts|
    if SiteSetting.mediabot_enabled
      Jobs.enqueue(:discourse_mediabot_reply, topic_id: topic.id)
    end
  end

  on(:post_created) do |post, opts|
    if SiteSetting.mediabot_enabled && SiteSetting.mediabot_enable_inline_commands
      Jobs.enqueue(:mediabot_inline_reply, post_id: post.id)
    end
  end

  # Register admin routes
  add_admin_route 'mediabot.title', 'mediabot'

  # Register stylesheets
  register_asset "stylesheets/mediabot.scss"

  # Register admin controller
  class ::Admin::MediaBotController < ::Admin::AdminController
    def index
      render json: {
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
        metrics: DiscourseMediaBot::Fetcher.metrics,
        errors: DiscourseMediaBot::ErrorHandler.recent_errors
      }
    end

    def clear_metrics
      DiscourseMediaBot::Fetcher.clear_metrics
      render json: success_json
    end

    def clear_errors
      DiscourseMediaBot::ErrorHandler.clear_errors
      render json: success_json
    end

    def test_api
      service = params[:service]
      title = params[:title]

      if title.blank?
        return render json: { error: I18n.t("mediabot.admin.test.title_required") }, status: 400
      end

      begin
        result = DiscourseMediaBot::Fetcher.fetch(service, title)
        render json: { result: result }
      rescue => e
        render json: { error: e.message }, status: 500
      end
    end
  end
end

Discourse::Application.routes.append do
  mount ::DiscourseMediaBot::Engine, at: "/mediabot"
  
  namespace :admin, constraints: StaffConstraint.new do
    get 'plugins/mediabot' => 'mediabot#index'
    put 'plugins/mediabot/settings' => 'mediabot#update_settings'
    post 'plugins/mediabot/clear_metrics' => 'mediabot#clear_metrics'
    post 'plugins/mediabot/clear_errors' => 'mediabot#clear_errors'
    post 'plugins/mediabot/test_api' => 'mediabot#test_api'
  end
end 