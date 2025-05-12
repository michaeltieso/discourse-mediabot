require 'rails_helper'

describe MediaBot::Fetcher do
  let(:movie_fetcher) { described_class.new('movie') }
  let(:tv_fetcher) { described_class.new('tv') }
  
  before do
    SiteSetting.mediabot_tmdb_api_key = 'test_tmdb_key'
    SiteSetting.mediabot_tvdb_api_key = 'test_tvdb_key'
  end
  
  describe '#initialize' do
    it 'raises error for missing API key' do
      SiteSetting.mediabot_tmdb_api_key = ''
      expect { described_class.new('movie') }.to raise_error(MediaBot::Fetcher::ApiError)
    end
    
    it 'raises error for unsupported media type' do
      expect { described_class.new('book') }.to raise_error(MediaBot::Fetcher::ApiError)
    end
  end
  
  describe '#fetch' do
    context 'with caching' do
      it 'uses cached data when available' do
        cache_key = "mediabot:movie:the iron claw:en-US"
        cached_data = { 'title' => 'The Iron Claw', 'year' => '2023' }
        
        Discourse.cache.write(cache_key, cached_data, expires_in: 24.hours)
        expect(movie_fetcher).not_to receive(:fetch_movie)
        
        result = movie_fetcher.fetch('The Iron Claw')
        expect(result).to eq(cached_data)
      end
      
      it 'caches new data' do
        movie_data = { 'title' => 'The Iron Claw', 'year' => '2023' }
        allow(movie_fetcher).to receive(:fetch_movie).and_return(movie_data)
        
        movie_fetcher.fetch('The Iron Claw')
        
        cached = Discourse.cache.read("mediabot:movie:the iron claw:en-US")
        expect(cached).to eq(movie_data)
      end
    end
    
    context 'with rate limiting' do
      it 'respects rate limits' do
        allow(Discourse.cache).to receive(:read).with(described_class::RATE_LIMIT_KEY).and_return(described_class::MAX_REQUESTS_PER_WINDOW)
        
        expect { movie_fetcher.fetch('The Iron Claw') }.to raise_error(MediaBot::Fetcher::RateLimitError)
      end
      
      it 'tracks request count' do
        expect(Discourse.cache).to receive(:write).with(
          described_class::RATE_LIMIT_KEY,
          1,
          expires_in: described_class::RATE_LIMIT_WINDOW
        )
        
        allow(movie_fetcher).to receive(:fetch_movie).and_return({})
        movie_fetcher.fetch('The Iron Claw')
      end
    end
  end
  
  describe '#fetch_movie' do
    it 'handles API errors' do
      stub_request(:get, /api.themoviedb.org/).to_return(status: 500)
      expect { movie_fetcher.send(:fetch_movie, 'The Iron Claw') }.to raise_error(MediaBot::Fetcher::ApiError)
    end
    
    it 'handles empty results' do
      stub_request(:get, /api.themoviedb.org/).to_return(
        status: 200,
        body: { results: [] }.to_json
      )
      
      result = movie_fetcher.send(:fetch_movie, 'The Iron Claw')
      expect(result).to be_nil
    end
  end
  
  describe '#fetch_tv_show' do
    it 'handles API errors' do
      stub_request(:get, /api4.thetvdb.com/).to_return(status: 500)
      expect { tv_fetcher.send(:fetch_tv_show, 'Breaking Bad') }.to raise_error(MediaBot::Fetcher::ApiError)
    end
    
    it 'handles empty results' do
      stub_request(:get, /api4.thetvdb.com/).to_return(
        status: 200,
        body: { data: [] }.to_json
      )
      
      result = tv_fetcher.send(:fetch_tv_show, 'Breaking Bad')
      expect(result).to be_nil
    end
  end
end 