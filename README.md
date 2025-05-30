# Discourse MediaBot Plugin

A Discourse plugin that automatically replies to topics and posts with movie and TV show information from TMDb and TVDb.

## Features

- **Multiple Trigger Methods**:
  - Topic-level detection with tags
  - Structured format: `[movie] Title (Year)`
  - Inline commands: `!movie` or `!tv` in any post
- **API Integration**:
  - TMDb for movies
  - TVDb for TV shows
  - Rate limiting and caching
  - Error handling with retries
- **Configurable Display Options**:
  - Title with year
  - Poster image
  - Overview/Summary
  - Release/Air date
  - Cast information
  - Rating (TMDb/IMDb/TVDb)
  - Genres
  - Runtime
  - External links
- **Smart Filtering**:
  - Category-based activation
  - Tag-based activation
  - Configurable delay for replies
- **User Experience**:
  - Beautiful Markdown formatting
  - Emoji-enhanced display
  - Proper post threading
  - Locale-aware responses
- **Localization**:
  - Multi-language support
  - User locale preference
  - Customizable emojis per locale
  - Fallback locale system
  - Right-to-left language support

## Installation

1. Add the plugin to your Discourse instance:
   ```bash
   cd /var/discourse
   ./launcher enter app
   cd /var/www/discourse
   git clone https://github.com/michaeltieso/discourse-mediabot plugins/discourse-mediabot
   ```

2. Rebuild your Discourse container:
   ```bash
   cd /var/discourse
   ./launcher rebuild app
   ```

3. Enable the plugin in your Discourse admin settings:
   - Go to Admin → Settings → Plugins → Discourse MediaBot

## Configuration

### API Keys

#### Obtaining API Keys

1. **TMDb API Key**:
   - Visit https://www.themoviedb.org/settings/api
   - Create an account or log in
   - Request an API key (v3 auth)
   - Note: Free tier includes 40 requests per 10 seconds

2. **TVDb API Key**:
   - Visit https://thetvdb.com/api-information
   - Create an account or log in
   - Generate an API key
   - Note: Free tier includes 100 requests per day

#### Setting Up API Keys

1. **In Discourse Admin**:
   - Go to Admin → Settings → Plugins → Discourse MediaBot
   - Enter your API keys in the respective fields
   - Keys are stored securely and marked as secrets
   - Changes take effect immediately

2. **Environment Variables** (Alternative):
   ```bash
   # In your Discourse environment
   export TMDb_API_KEY=your_key_here
   export TVDb_API_KEY=your_key_here
   ```

3. **Security Best Practices**:
   - Never commit API keys to version control
   - Use different keys for development and production
   - Regularly rotate keys
   - Monitor API usage
   - Set up rate limit alerts

### Display Options

Configure which information to show in the bot's reply:
- Title
- Poster
- Overview/Summary
- Release/Air date
- Cast
- Rating
- Genres
- Runtime
- External links

### Activation Settings

- Enable/disable specific categories
- Set which tags trigger the bot (default: 'movie', 'tv')
- Toggle inline commands
- Configure reply delay

### Localization Settings

- Default locale (default: 'en-US')
- Use user's preferred locale
- Fallback locale for missing translations
- Supported locales list
- Custom emojis per locale
- Error message translations

## Usage

### Topic-Level Format

Discourse MediaBot supports two ways to trigger a response in new topics:

1. Using tags:
   - Add the 'movie' or 'tv' tag to your topic
   - Include the title in your post (e.g., "What did you think of The Iron Claw?")

2. Using structured format:
   - `[movie] The Iron Claw (2023)`
   - `[tv] Breaking Bad`

### Inline Commands

Use Discourse MediaBot in any post with these commands:
- `!movie The Iron Claw (2023)`
- `!tv Breaking Bad`

The bot will reply to your post with the media information, properly threaded in the conversation.

## Example Responses

### Movie Example
```
🎬 **The Iron Claw (2023)**
![Poster](https://image.tmdb.org/t/p/w500/...)
*The true story of the inseparable Von Erich brothers...*
⭐️ Rating: 7.9/10
⏱ Runtime: 132 minutes
👥 Cast: Zac Efron, Jeremy Allen White
🎭 Genres: Drama, Biography, Sport
🔗 [View on TMDb](https://www.themoviedb.org/movie/...)
```

### TV Show Example
```
📺 **Breaking Bad (2008)**
![Poster](https://thetvdb.com/images/...)
*A high school chemistry teacher diagnosed with cancer...*
⭐️ Rating: 9.5/10
⏱ Runtime: 45 minutes
👥 Cast: Bryan Cranston, Aaron Paul
🎭 Genres: Drama, Crime, Thriller
🔗 [View on TVDb](https://thetvdb.com/series/...)
```

## Development

### Requirements

- Ruby 2.7+
- Discourse 2.8.0+
- Redis (for caching)
- API keys for TMDb and/or TVDb

### Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/michaeltieso/discourse-mediabot
   cd discourse-mediabot
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up test environment:
   ```bash
   bundle exec rake db:create db:migrate RAILS_ENV=test
   ```

4. Configure API keys in test environment:
   ```bash
   export TMDb_API_KEY=your_key
   export TVDb_API_KEY=your_key
   ```

### Testing

The plugin includes a comprehensive test suite covering:

- Title parsing and detection
- API response handling
- Post creation logic
- Admin setting behavior
- Error handling
- Caching mechanisms
- Rate limiting
- Localization

To run the tests:

```bash
bundle exec rspec
```

## Development Status

### ✅ Implemented Features

- Basic movie and TV show information fetching
- Title detection with structured format and inline commands
- Configurable reply formatting
- API key management
- Category and tag filtering
- Caching system
- Rate limiting
- Localization support
- Comprehensive test suite

### 🚧 In Progress

- Enhanced error handling
- Performance optimizations
- Admin UI improvements

### 📋 Planned Features

1. **Future Media Types**
   - Book information (Goodreads/Google Books API)
   - Game information (IGDB API)
   - Music information (Last.fm/Spotify API)

2. **Enhanced Features**
   - Emoji reactions for "Add to Watchlist"
   - Automatic tagging based on genre/metadata
   - Rich media previews
   - User watchlist integration
   - Similar media recommendations

3. **Performance Improvements**
   - Cache warming for popular media
   - Batch processing for multiple requests
   - Performance monitoring
   - Response time optimization

4. **User Experience**
   - Custom reply templates
   - User preferences
   - Media comparison tools
   - Watchlist management
   - Media recommendations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for your changes
4. Ensure all tests pass
5. Submit a pull request

## Troubleshooting

### Common Issues

1. **API Rate Limits**
   - TMDb: 40 requests per 10 seconds
   - TVDb: 100 requests per day
   - Solution: Implement caching and monitor usage

2. **Missing Media Information**
   - Check API response format
   - Verify title parsing
   - Ensure API keys are valid

3. **Performance Issues**
   - Check cache configuration
   - Monitor API response times
   - Review rate limiting settings

### Debugging

1. Enable debug logging:
   ```ruby
   SiteSetting.mediabot_debug = true
   ```

2. Check logs:
   ```bash
   tail -f log/development.log
   ```

3. Monitor API usage:
   ```ruby
   DiscourseMediaBot::Fetcher.api_usage
   ```

## License

MIT License - see LICENSE file for details 