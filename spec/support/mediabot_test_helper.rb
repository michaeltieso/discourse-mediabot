module MediaBotTestHelper
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def with_mediabot_enabled
      before do
        SiteSetting.mediabot_enabled = true
        SiteSetting.mediabot_tmdb_api_key = 'test_tmdb_key'
        SiteSetting.mediabot_tvdb_api_key = 'test_tvdb_key'
      end
    end
    
    def with_mediabot_disabled
      before do
        SiteSetting.mediabot_enabled = false
      end
    end
  end
  
  def create_movie_data(overrides = {})
    {
      'title' => 'The Iron Claw',
      'year' => '2023',
      'overview' => 'The true story of the inseparable Von Erich brothers...',
      'poster_path' => '/poster.jpg',
      'vote_average' => 7.9,
      'runtime' => 132,
      'genres' => [{ 'name' => 'Drama' }, { 'name' => 'Biography' }],
      'credits' => {
        'cast' => [
          { 'name' => 'Zac Efron', 'character' => 'Kevin Von Erich' },
          { 'name' => 'Jeremy Allen White', 'character' => 'Kerry Von Erich' }
        ]
      }
    }.merge(overrides)
  end
  
  def create_tv_data(overrides = {})
    {
      'name' => 'Breaking Bad',
      'first_air_date' => '2008-01-20',
      'overview' => 'A high school chemistry teacher turned methamphetamine manufacturer...',
      'poster_path' => '/poster.jpg',
      'vote_average' => 9.5,
      'episode_run_time' => [45],
      'genres' => [{ 'name' => 'Drama' }, { 'name' => 'Crime' }],
      'credits' => {
        'cast' => [
          { 'name' => 'Bryan Cranston', 'character' => 'Walter White' },
          { 'name' => 'Aaron Paul', 'character' => 'Jesse Pinkman' }
        ]
      }
    }.merge(overrides)
  end
  
  def create_movie_topic
    topic = Fabricate(:topic)
    topic.tags << Tag.find_or_create_by(name: 'movie')
    Fabricate(:post, topic: topic, raw: 'The Iron Claw (2023)')
    topic
  end
  
  def create_tv_topic
    topic = Fabricate(:topic)
    topic.tags << Tag.find_or_create_by(name: 'tv')
    Fabricate(:post, topic: topic, raw: 'Breaking Bad (2008)')
    topic
  end
  
  def create_movie_command_post
    topic = Fabricate(:topic)
    Fabricate(:post, topic: topic, raw: '!movie The Iron Claw (2023)')
  end
  
  def create_tv_command_post
    topic = Fabricate(:topic)
    Fabricate(:post, topic: topic, raw: '!tv Breaking Bad (2008)')
  end
end

RSpec.configure do |config|
  config.include MediaBotTestHelper, type: :job
  config.include MediaBotTestHelper, type: :service
end 