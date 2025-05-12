module MediaBot
  class Fetcher
    class ApiError < StandardError; end
    class RateLimitError < StandardError; end
    
    CACHE_DURATION = 24.hours
    RATE_LIMIT_KEY = "mediabot:rate_limit"
    RATE_LIMIT_WINDOW = 1.minute
    MAX_REQUESTS_PER_WINDOW = 30
    
    def initialize(media_type)
      @media_type = media_type
      @api_key = case media_type
                when 'movie'
                  SiteSetting.mediabot_tmdb_api_key
                when 'tv'
                  SiteSetting.mediabot_tvdb_api_key
                end
      
      raise ApiError, "No API key configured for #{media_type}" if @api_key.blank?
    end
    
    def fetch(title, locale: 'en-US')
      check_rate_limit!
      
      cache_key = "mediabot:#{@media_type}:#{title.downcase}:#{locale}"
      
      # Try to get from cache first
      cached_data = Discourse.cache.read(cache_key)
      return cached_data if cached_data.present?
      
      # Fetch from API if not in cache
      data = case @media_type
             when 'movie'
               fetch_movie(title, locale)
             when 'tv'
               fetch_tv_show(title, locale)
             else
               raise ApiError, "Unsupported media type: #{@media_type}"
             end
      
      # Cache the result
      Discourse.cache.write(cache_key, data, expires_in: CACHE_DURATION) if data.present?
      
      data
    end
    
    private
    
    def check_rate_limit!
      current = Discourse.cache.read(RATE_LIMIT_KEY) || 0
      
      if current >= MAX_REQUESTS_PER_WINDOW
        raise RateLimitError, "Rate limit exceeded. Please try again later."
      end
      
      Discourse.cache.write(RATE_LIMIT_KEY, current + 1, expires_in: RATE_LIMIT_WINDOW)
    end
    
    def fetch_movie(title, locale)
      # Search TMDb API
      search_url = "https://api.themoviedb.org/3/search/movie"
      search_params = {
        api_key: @api_key,
        query: title,
        language: locale
      }
      
      response = Excon.get(search_url, query: search_params)
      raise ApiError, "TMDb API error: #{response.status}" unless response.status == 200
      
      results = JSON.parse(response.body)['results']
      return nil if results.empty?
      
      # Get details for the first result
      movie_id = results.first['id']
      details_url = "https://api.themoviedb.org/3/movie/#{movie_id}"
      details_params = {
        api_key: @api_key,
        append_to_response: 'credits',
        language: locale
      }
      
      response = Excon.get(details_url, query: details_params)
      raise ApiError, "TMDb API error: #{response.status}" unless response.status == 200
      
      JSON.parse(response.body)
    end
    
    def fetch_tv_show(title, locale)
      # Search TVDb API
      search_url = "https://api4.thetvdb.com/v4/search"
      search_params = {
        query: title,
        type: 'series',
        language: locale
      }
      
      response = Excon.get(search_url, 
        query: search_params,
        headers: { 'Authorization' => "Bearer #{@api_key}" }
      )
      raise ApiError, "TVDb API error: #{response.status}" unless response.status == 200
      
      results = JSON.parse(response.body)['data']
      return nil if results.empty?
      
      # Get details for the first result
      series_id = results.first['id']
      details_url = "https://api4.thetvdb.com/v4/series/#{series_id}/extended"
      
      response = Excon.get(details_url,
        headers: { 'Authorization' => "Bearer #{@api_key}" }
      )
      raise ApiError, "TVDb API error: #{response.status}" unless response.status == 200
      
      JSON.parse(response.body)['data']
    end
  end
end 