module Admin
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
            show_links: SiteSetting.mediabot_show_links
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