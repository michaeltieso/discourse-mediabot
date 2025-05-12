module MediaBot
  class ReplyFormatter
    def initialize(media_data, media_type, locale: 'en-US')
      @data = media_data
      @type = media_type
      @locale = locale
    end
    
    def format
      return "Sorry, I couldn't find any information about that title." if @data.nil?
      
      parts = []
      
      # Title
      if SiteSetting.mediabot_show_title
        parts << format_title
      end
      
      # Poster
      if SiteSetting.mediabot_show_poster
        parts << format_poster
      end
      
      # Overview
      if SiteSetting.mediabot_show_overview
        parts << format_overview
      end
      
      # Release/Air Date
      if SiteSetting.mediabot_show_release_date
        parts << format_release_date
      end
      
      # Cast
      if SiteSetting.mediabot_show_cast
        parts << format_cast
      end
      
      # Rating
      if SiteSetting.mediabot_show_rating
        parts << format_rating
      end
      
      # Genres
      if SiteSetting.mediabot_show_genres
        parts << format_genres
      end
      
      # Runtime
      if SiteSetting.mediabot_show_runtime
        parts << format_runtime
      end
      
      # External Links
      if SiteSetting.mediabot_show_external_links
        parts << format_external_links
      end
      
      parts.compact.join("\n\n")
    end
    
    private
    
    def t(key, default: nil)
      I18n.t("mediabot.#{key}", locale: @locale, default: default)
    end
    
    def format_title
      case @type
      when 'movie'
        "#{t('movie_emoji', default: '🎬')} **#{@data['title']}** (#{@data['release_date']&.split('-')&.first})"
      when 'tv'
        "#{t('tv_emoji', default: '📺')} **#{@data['name']}** (#{@data['firstAired']&.split('-')&.first})"
      end
    end
    
    def format_poster
      case @type
      when 'movie'
        poster_path = @data['poster_path']
        return nil unless poster_path
        "![#{t('poster_alt', default: 'Poster')}](https://image.tmdb.org/t/p/w500#{poster_path})"
      when 'tv'
        image = @data['image']
        return nil unless image
        "![#{t('poster_alt', default: 'Poster')}](#{image})"
      end
    end
    
    def format_overview
      case @type
      when 'movie'
        "*#{@data['overview']}*"
      when 'tv'
        "*#{@data['overview']}*"
      end
    end
    
    def format_release_date
      case @type
      when 'movie'
        "#{t('release_date_emoji', default: '📅')} #{t('release_date', default: 'Release Date')}: #{@data['release_date']}"
      when 'tv'
        "#{t('release_date_emoji', default: '📅')} #{t('first_aired', default: 'First Aired')}: #{@data['firstAired']}"
      end
    end
    
    def format_cast
      case @type
      when 'movie'
        cast = @data.dig('credits', 'cast')&.first(3)&.map { |c| c['name'] }
        return nil unless cast&.any?
        "#{t('cast_emoji', default: '👥')} #{t('cast', default: 'Cast')}: #{cast.join(', ')}"
      when 'tv'
        cast = @data['characters']&.first(3)&.map { |c| c['personName'] }
        return nil unless cast&.any?
        "#{t('cast_emoji', default: '👥')} #{t('cast', default: 'Cast')}: #{cast.join(', ')}"
      end
    end
    
    def format_rating
      case @type
      when 'movie'
        "#{t('rating_emoji', default: '⭐️')} #{t('rating', default: 'Rating')}: #{@data['vote_average']}/10"
      when 'tv'
        "#{t('rating_emoji', default: '⭐️')} #{t('rating', default: 'Rating')}: #{@data['score']}/10"
      end
    end
    
    def format_genres
      case @type
      when 'movie'
        genres = @data['genres']&.map { |g| g['name'] }
        return nil unless genres&.any?
        "#{t('genres_emoji', default: '🎭')} #{t('genres', default: 'Genres')}: #{genres.join(', ')}"
      when 'tv'
        genres = @data['genres']
        return nil unless genres&.any?
        "#{t('genres_emoji', default: '🎭')} #{t('genres', default: 'Genres')}: #{genres.join(', ')}"
      end
    end
    
    def format_runtime
      case @type
      when 'movie'
        "#{t('runtime_emoji', default: '⏱')} #{t('runtime', default: 'Runtime')}: #{@data['runtime']} #{t('minutes', default: 'minutes')}"
      when 'tv'
        "#{t('runtime_emoji', default: '⏱')} #{t('runtime', default: 'Runtime')}: #{@data['runtime']} #{t('minutes', default: 'minutes')}"
      end
    end
    
    def format_external_links
      case @type
      when 'movie'
        tmdb_id = @data['id']
        "#{t('link_emoji', default: '🔗')} [#{t('view_on_tmdb', default: 'View on TMDb')}](https://www.themoviedb.org/movie/#{tmdb_id})"
      when 'tv'
        tvdb_id = @data['id']
        "#{t('link_emoji', default: '🔗')} [#{t('view_on_tvdb', default: 'View on TVDb')}](https://thetvdb.com/series/#{tvdb_id})"
      end
    end
  end
end 