module Jobs
  class MediaBotReply < ::Jobs::Base
    def execute(args)
      topic = Topic.find_by(id: args[:topic_id])
      return if topic.nil?
      
      # Find or create bot user
      bot_user = find_or_create_bot_user
      return if bot_user.nil?
      
      # Parse the topic content
      parser = MediaBot::TitleParser.new(topic)
      return unless parser.should_process?
      
      media_info = parser.parse
      return if media_info.nil?
      
      # Get user's locale
      locale = topic.user&.locale || 'en-US'
      
      # Fetch media data
      begin
        fetcher = MediaBot::Fetcher.new(media_info[:type])
        media_data = fetcher.fetch(media_info[:title], locale: locale)
      rescue MediaBot::Fetcher::ApiError => e
        Rails.logger.error("MediaBot API error: #{e.message}")
        return
      rescue MediaBot::Fetcher::RateLimitError => e
        Rails.logger.error("MediaBot rate limit exceeded: #{e.message}")
        # Retry the job after a delay
        Jobs.enqueue_in(5.minutes, :mediabot_reply, topic_id: topic.id)
        return
      end
      
      # Format the reply
      formatter = MediaBot::ReplyFormatter.new(media_data, media_info[:type])
      reply_content = formatter.format
      
      # Create the reply post
      PostCreator.create!(
        bot_user,
        topic_id: topic.id,
        raw: reply_content,
        skip_validations: true
      )
    end
    
    private
    
    def find_or_create_bot_user
      # Try to find existing bot user
      bot_user = User.find_by(username: 'MediaBot')
      return bot_user if bot_user
      
      # Create new bot user if not found
      begin
        bot_user = User.create!(
          username: 'MediaBot',
          email: 'mediabot@example.com',
          password: SecureRandom.hex(20),
          active: true,
          trust_level: TrustLevel[1],
          manual_locked_trust_level: TrustLevel[1],
          approved: true,
          approved_by_id: -1,
          approved_at: Time.current
        )
        
        # Add bot user to staff group
        staff_group = Group.find_by(name: 'staff')
        staff_group&.add(bot_user)
        
        bot_user
      rescue => e
        Rails.logger.error("Failed to create MediaBot user: #{e.message}")
        nil
      end
    end
  end
end 