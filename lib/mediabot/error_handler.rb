module DiscourseMediaBot
  class ErrorHandler
    class Error < StandardError; end
    class ApiError < Error; end
    class RateLimitError < Error; end
    class ConfigurationError < Error; end
    class ValidationError < Error; end
    class CacheError < Error; end
    
    def self.handle_error(error, context = {})
      error_details = {
        message: error.message,
        backtrace: error.backtrace&.first(5),
        context: context,
        timestamp: Time.current
      }
      
      # Log the error
      Rails.logger.error("DiscourseMediaBot Error: #{error_details.to_json}")
      
      # Store in Redis for monitoring
      begin
        store_error(error_details)
      rescue Redis::CommandError => e
        Rails.logger.error("DiscourseMediaBot error storage failed: #{e.message}")
        # Continue without storing error
      end
      
      # Return user-friendly message
      format_error_message(error)
    end
    
    def self.store_error(error_details)
      key = "mediabot:errors:#{Time.current.strftime('%Y%m%d')}"
      begin
        Discourse.redis.lpush(key, error_details.to_json)
        Discourse.redis.ltrim(key, 0, 999) # Keep last 1000 errors
      rescue Redis::CommandError => e
        Rails.logger.error("DiscourseMediaBot error storage failed: #{e.message}")
        raise CacheError, "Failed to store error: #{e.message}"
      end
    end
    
    def self.get_recent_errors(limit = 50)
      key = "mediabot:errors:#{Time.current.strftime('%Y%m%d')}"
      begin
        errors = Discourse.redis.lrange(key, 0, limit - 1)
        errors.map { |e| JSON.parse(e) }
      rescue Redis::CommandError => e
        Rails.logger.error("DiscourseMediaBot error retrieval failed: #{e.message}")
        []
      end
    end
    
    def self.clear_errors
      key = "mediabot:errors:#{Time.current.strftime('%Y%m%d')}"
      begin
        Discourse.redis.del(key)
      rescue Redis::CommandError => e
        Rails.logger.error("DiscourseMediaBot error clearing failed: #{e.message}")
        raise CacheError, "Failed to clear errors: #{e.message}"
      end
    end
    
    private
    
    def self.format_error_message(error)
      case error
      when ApiError
        I18n.t('mediabot.errors.api_error',
          message: error.message
        )
      when RateLimitError
        I18n.t('mediabot.errors.rate_limit',
          message: error.message
        )
      when ConfigurationError
        I18n.t('mediabot.errors.configuration',
          message: error.message
        )
      when ValidationError
        I18n.t('mediabot.errors.validation',
          message: error.message
        )
      when CacheError
        I18n.t('mediabot.errors.cache',
          message: error.message
        )
      else
        I18n.t('mediabot.errors.generic',
          message: error.message
        )
      end
    end
  end
end 