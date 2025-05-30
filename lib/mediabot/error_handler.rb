module DiscourseMediaBot
  class ErrorHandler
    class Error < StandardError; end
    class ApiError < Error; end
    class RateLimitError < Error; end
    class ConfigurationError < Error; end
    class ValidationError < Error; end
    
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
      store_error(error_details)
      
      # Return user-friendly message
      format_error_message(error)
    end
    
    def self.store_error(error_details)
      key = "discourse-mediabot:errors:#{Time.current.strftime('%Y%m%d')}"
      $redis.lpush(key, error_details.to_json)
      $redis.ltrim(key, 0, 999) # Keep last 1000 errors
    end
    
    def self.get_recent_errors(limit = 50)
      key = "discourse-mediabot:errors:#{Time.current.strftime('%Y%m%d')}"
      errors = $redis.lrange(key, 0, limit - 1)
      errors.map { |e| JSON.parse(e) }
    end
    
    def self.clear_errors
      key = "discourse-mediabot:errors:#{Time.current.strftime('%Y%m%d')}"
      $redis.del(key)
    end
    
    private
    
    def self.format_error_message(error)
      case error
      when ApiError
        I18n.t('discourse-mediabot.errors.api_error',
          message: error.message
        )
      when RateLimitError
        I18n.t('discourse-mediabot.errors.rate_limit',
          message: error.message
        )
      when ConfigurationError
        I18n.t('discourse-mediabot.errors.configuration',
          message: error.message
        )
      when ValidationError
        I18n.t('discourse-mediabot.errors.validation',
          message: error.message
        )
      else
        I18n.t('discourse-mediabot.errors.generic',
          message: error.message
        )
      end
    end
  end
end 