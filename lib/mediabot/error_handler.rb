module MediaBot
  class ErrorHandler
    class Error < StandardError; end
    class ApiError < Error; end
    class RateLimitError < Error; end
    class ConfigurationError < Error; end
    class ValidationError < Error; end
    
    def self.handle_error(error, context = {})
      error_type = error.class.name.demodulize
      error_message = error.message
      error_details = {
        type: error_type,
        message: error_message,
        context: context,
        timestamp: Time.current,
        backtrace: error.backtrace&.first(5)
      }
      
      # Log the error
      Rails.logger.error("MediaBot Error: #{error_details.to_json}")
      
      # Store in Redis for monitoring
      store_error(error_details)
      
      # Return user-friendly message
      user_friendly_message(error_type, error_message, context)
    end
    
    def self.store_error(error_details)
      key = "mediabot:errors:#{Time.current.strftime('%Y%m%d')}"
      Discourse.redis.lpush(key, error_details.to_json)
      Discourse.redis.expire(key, 7.days.to_i)
    end
    
    def self.get_recent_errors(limit = 100)
      key = "mediabot:errors:#{Time.current.strftime('%Y%m%d')}"
      errors = Discourse.redis.lrange(key, 0, limit - 1)
      errors.map { |e| JSON.parse(e) }
    end
    
    def self.clear_errors
      key = "mediabot:errors:#{Time.current.strftime('%Y%m%d')}"
      Discourse.redis.del(key)
    end
    
    private
    
    def self.user_friendly_message(error_type, error_message, context)
      case error_type
      when 'ApiError'
        I18n.t('mediabot.errors.api_error',
          title: context[:title],
          type: context[:type],
          message: error_message
        )
      when 'RateLimitError'
        I18n.t('mediabot.errors.rate_limit',
          service: context[:service],
          retry_after: context[:retry_after]
        )
      when 'ConfigurationError'
        I18n.t('mediabot.errors.configuration',
          setting: context[:setting],
          message: error_message
        )
      when 'ValidationError'
        I18n.t('mediabot.errors.validation',
          field: context[:field],
          message: error_message
        )
      else
        I18n.t('mediabot.errors.generic',
          message: error_message
        )
      end
    end
  end
end 