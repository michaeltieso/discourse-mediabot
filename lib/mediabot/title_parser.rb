module MediaBot
  class TitleParser
    class ParseError < StandardError; end
    
    def initialize(topic_or_post)
      @topic_or_post = topic_or_post
      @content = topic_or_post.respond_to?(:raw) ? topic_or_post.raw : topic_or_post.first_post&.raw
      @tags = topic_or_post.respond_to?(:tags) ? topic_or_post.tags.pluck(:name) : topic_or_post.topic.tags.pluck(:name)
    end
    
    def parse
      return nil if @content.blank?
      
      # First try inline command format !movie or !tv
      if match = @content.match(/!(movie|tv)\s+(.+?)(?:\s*\((\d{4})\))?/i)
        return {
          type: match[1].downcase,
          title: match[2].strip,
          year: match[3],
          is_inline: true
        }
      end
      
      # Then try structured format [type] Title (Year)
      if match = @content.match(/\[(movie|tv)\]\s*(.+?)(?:\s*\((\d{4})\))?/i)
        return {
          type: match[1].downcase,
          title: match[2].strip,
          year: match[3],
          is_inline: false
        }
      end
      
      # If no structured format, try to determine from tags
      media_type = @tags.find { |tag| ['movie', 'tv'].include?(tag.downcase) }
      return nil unless media_type
      
      # Extract title and optional year
      if match = @content.match(/(.+?)(?:\s*\((\d{4})\))?/i)
        return {
          type: media_type,
          title: match[1].strip,
          year: match[2],
          is_inline: false
        }
      end
      
      nil
    end
    
    def should_process?
      return false if @content.blank?
      
      # For inline commands, we don't need to check tags
      if @content.match(/!(movie|tv)\s+/i)
        return true
      end
      
      return false if @tags.empty?
      
      # Check if any enabled tags are present
      enabled_tags = SiteSetting.mediabot_enabled_tags.split(',')
      return false unless (@tags & enabled_tags).any?
      
      # Check if topic is in enabled category
      if enabled_categories = SiteSetting.mediabot_enabled_categories.presence
        enabled_categories = enabled_categories.split(',')
        return false unless enabled_categories.include?(@topic_or_post.topic.category_id.to_s)
      end
      
      true
    end
  end
end 