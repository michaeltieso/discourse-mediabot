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
      
      track_metric(:api_response_time, service, duration)
      track_metric(:request_count, service, 1)
      
      result
    rescue StandardError => e
      track_metric(:error_count, service, 1)
      raise e
    end
    
    def self.track_cache_hit(service)
      track_metric(:cache_hits, service, 1)
    end
    
    def self.track_cache_miss(service)
      track_metric(:cache_misses, service, 1)
    end
    
    def self.get_metrics(service, time_range = 24.hours)
      start_time = Time.current - time_range
      
      METRICS.transform_values do |key|
        get_metric(key, service, start_time)
      end
    end
    
    def self.clear_metrics
      METRICS.each_value do |key|
        Discourse.redis.del(key)
      end
    end
    
    private
    
    def self.track_metric(metric, service, value)
      key = "#{METRICS[metric]}:#{service}:#{Time.current.strftime('%Y%m%d%H')}"
      Discourse.redis.zincrby(key, value, Time.current.to_i)
      Discourse.redis.expire(key, 7.days.to_i)
    end
    
    def self.get_metric(key, service, start_time)
      hourly_keys = (start_time.to_i..Time.current.to_i).step(1.hour).map do |timestamp|
        "#{key}:#{service}:#{Time.at(timestamp).strftime('%Y%m%d%H')}"
      end
      
      values = hourly_keys.map do |hourly_key|
        Discourse.redis.zrange(hourly_key, 0, -1, withscores: true)
      end.flatten(1)
      
      values.group_by { |_, score| Time.at(score).strftime('%Y-%m-%d %H:00') }
            .transform_values { |v| v.sum { |val, _| val.to_f } }
    end
  end
end 