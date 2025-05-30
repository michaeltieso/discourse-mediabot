module Jobs
  class DiscourseMediaBotInlineReply < ::Jobs::Base
    def execute(args)
      return unless args[:post_id]
      
      post = Post.find_by(id: args[:post_id])
      return unless post
      
      # Parse the post content for media information
      parser = DiscourseMediaBot::TitleParser.new(post)
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
        Jobs.enqueue_in(5.minutes, :discourse_mediabot_inline_reply, post_id: post.id)
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
        topic_id: post.topic_id,
        raw: reply_content,
        reply_to_post_number: post.post_number,
        skip_validations: true
      )
    end
  end
end 