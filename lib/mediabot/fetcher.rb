module DiscourseMediaBot
  class Fetcher
    class ApiError < StandardError; end
    class RateLimitError < StandardError; end
    
    CACHE_EXPIRY = 24.hours.to_i
    RATE_LIMIT_KEY = "discourse-mediabot:rate_limit"
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
    
    def fetch(title)
      locale = I18n.locale
      cache_key = "discourse-mediabot:#{@media_type}:#{title.downcase}:#{locale}"
      
      # Check cache first
      cached_result = $redis.get(cache_key)
      return JSON.parse(cached_result) if cached_result

      # Check rate limit
      check_rate_limit

      # Fetch from API
      result = case @media_type
               when 'movie'
                 fetch_from_tmdb(title)
               when 'tv'
                 fetch_from_tvdb(title)
               else
                 raise ApiError, "Unsupported media type: #{@media_type}"
               end

      # Cache the result
      $redis.setex(cache_key, CACHE_EXPIRY, result.to_json)
      
      result
    end
    
    private
    
    def check_rate_limit
      current = $redis.get(RATE_LIMIT_KEY).to_i
      if current >= rate_limit
        raise RateLimitError, "Rate limit exceeded. Try again later."
      end
      $redis.incr(RATE_LIMIT_KEY)
      $redis.expire(RATE_LIMIT_KEY, rate_limit_window)
    end
    
    def rate_limit
      case @media_type
      when 'movie'
        40 # TMDb: 40 requests per 10 seconds
      when 'tv'
        100 # TVDb: 100 requests per day
      end
    end
    
    def rate_limit_window
      case @media_type
      when 'movie'
        10.seconds.to_i
      when 'tv'
        24.hours.to_i
      end
    end
    
    def fetch_from_tmdb(title)
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
    
    def fetch_from_tvdb(title)
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