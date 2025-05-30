module MediaBot
  class PerformanceMonitor
    METRICS = {
      api_response_time: 'mediabot:metrics:api_response_time',
      cache_hits: 'mediabot:metrics:cache_hits',
      cache_misses: 'mediabot:metrics:cache_misses',
      error_count: 'mediabot:metrics:error_count',
      request_count: 'mediabot:metrics:request_count'
    }
    
    def self.track_api_call(service, &block)
      start_time = Time.current
      result = yield
      duration = Time.current - start_time
      
      begin
        track_metric(:api_response_time, service, duration)
        track_metric(:request_count, service, 1)
      rescue Redis::CommandError => e
        Rails.logger.error("DiscourseMediaBot metrics tracking failed: #{e.message}")
        # Continue without tracking
      end
      
      result
    rescue StandardError => e
      begin
        track_metric(:error_count, service, 1)
      rescue Redis::CommandError => redis_error
        Rails.logger.error("DiscourseMediaBot error tracking failed: #{redis_error.message}")
      end
      raise e
    end
    
    def self.track_cache_hit(service)
      begin
        track_metric(:cache_hits, service, 1)
      rescue Redis::CommandError => e
        Rails.logger.error("DiscourseMediaBot cache hit tracking failed: #{e.message}")
      end
    end
    
    def self.track_cache_miss(service)
      begin
        track_metric(:cache_misses, service, 1)
      rescue Redis::CommandError => e
        Rails.logger.error("DiscourseMediaBot cache miss tracking failed: #{e.message}")
      end
    end
    
    def self.get_metrics(service, time_range = 24.hours)
      start_time = Time.current - time_range
      
      METRICS.transform_values do |key|
        begin
          get_metric(key, service, start_time)
        rescue Redis::CommandError => e
          Rails.logger.error("DiscourseMediaBot metrics retrieval failed: #{e.message}")
          {}
        end
      end
    end
    
    def self.clear_metrics
      begin
        METRICS.each_value do |key|
          Discourse.redis.del(key)
        end
      rescue Redis::CommandError => e
        Rails.logger.error("DiscourseMediaBot metrics clearing failed: #{e.message}")
        raise CacheError, "Failed to clear metrics: #{e.message}"
      end
    end
    
    private
    
    def self.track_metric(metric, service, value)
      key = "#{METRICS[metric]}:#{service}:#{Time.current.strftime('%Y%m%d%H')}"
      begin
        Discourse.redis.zincrby(key, value, Time.current.to_i)
        Discourse.redis.expire(key, 7.days.to_i)
      rescue Redis::CommandError => e
        Rails.logger.error("DiscourseMediaBot metric tracking failed: #{e.message}")
        raise CacheError, "Failed to track metric: #{e.message}"
      end
    end
    
    def self.get_metric(key, service, start_time)
      hourly_keys = (start_time.to_i..Time.current.to_i).step(1.hour).map do |timestamp|
        "#{key}:#{service}:#{Time.at(timestamp).strftime('%Y%m%d%H')}"
      end
      
      begin
        values = hourly_keys.map do |hourly_key|
          Discourse.redis.zrange(hourly_key, 0, -1, withscores: true)
        end.flatten(1)
        
        values.group_by { |_, score| Time.at(score).strftime('%Y-%m-%d %H:00') }
              .transform_values { |v| v.sum { |val, _| val.to_f } }
      rescue Redis::CommandError => e
        Rails.logger.error("DiscourseMediaBot metric retrieval failed: #{e.message}")
        {}
      end
    end
  end
end 