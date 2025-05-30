module Jobs
  class DiscourseMediaBotReply < ::Jobs::Base
    def execute(args)
      return unless args[:topic_id]
      
      topic = Topic.find_by(id: args[:topic_id])
      return unless topic
      
      # Parse the topic title for media information
      parser = DiscourseMediaBot::TitleParser.new(topic)
      media_info = parser.parse
      
      return unless media_info
      
      begin
        # Fetch media information
        fetcher = DiscourseMediaBot::Fetcher.new(media_info[:type])
        media_data = fetcher.fetch(media_info[:title])
        
      rescue DiscourseMediaBot::Fetcher::ApiError => e
        Rails.logger.error("DiscourseMediaBot API error: #{e.message}")
        return
        
      rescue DiscourseMediaBot::Fetcher::RateLimitError => e
        Rails.logger.error("DiscourseMediaBot rate limit exceeded: #{e.message}")
        # Retry after rate limit window
        Jobs.enqueue_in(5.minutes, :discourse_mediabot_reply, topic_id: topic.id)
        return
      end
      
      # Format the reply
      formatter = DiscourseMediaBot::ReplyFormatter.new(media_data, media_info[:type])
      reply_content = formatter.format
      
      # Create or find the bot user
      bot_user = User.find_by(username: 'DiscourseMediaBot')
      
      unless bot_user
        begin
          bot_user = User.create!(
            username: 'DiscourseMediaBot',
            email: 'mediabot@example.com',
            password: SecureRandom.hex(20),
            active: true,
            trust_level: TrustLevel[1],
            approved: true,
            approved_by_id: -1,
            approved_at: Time.current
          )
        rescue => e
          Rails.logger.error("Failed to create DiscourseMediaBot user: #{e.message}")
          return
        end
      end
      
      # Create the reply
      PostCreator.create!(
        bot_user,
        topic_id: topic.id,
        raw: reply_content,
        skip_validations: true
      )
    end
  end
end 