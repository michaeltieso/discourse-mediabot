require 'rails_helper'

describe MediaBot do
  include MediaBotTestHelper
  
  describe '.enabled?' do
    it 'returns true when enabled' do
      SiteSetting.mediabot_enabled = true
      expect(described_class.enabled?).to be true
    end
    
    it 'returns false when disabled' do
      SiteSetting.mediabot_enabled = false
      expect(described_class.enabled?).to be false
    end
  end
  
  describe '.api_keys_configured?' do
    it 'returns true when both API keys are set' do
      SiteSetting.mediabot_tmdb_api_key = 'test_tmdb_key'
      SiteSetting.mediabot_tvdb_api_key = 'test_tvdb_key'
      expect(described_class.api_keys_configured?).to be true
    end
    
    it 'returns false when TMDb API key is missing' do
      SiteSetting.mediabot_tmdb_api_key = ''
      SiteSetting.mediabot_tvdb_api_key = 'test_tvdb_key'
      expect(described_class.api_keys_configured?).to be false
    end
    
    it 'returns false when TVDb API key is missing' do
      SiteSetting.mediabot_tmdb_api_key = 'test_tmdb_key'
      SiteSetting.mediabot_tvdb_api_key = ''
      expect(described_class.api_keys_configured?).to be false
    end
  end
  
  describe '.enabled_tags' do
    it 'returns array of enabled tags' do
      SiteSetting.mediabot_enabled_tags = 'movie,tv'
      expect(described_class.enabled_tags).to eq(['movie', 'tv'])
    end
    
    it 'returns empty array when no tags enabled' do
      SiteSetting.mediabot_enabled_tags = ''
      expect(described_class.enabled_tags).to eq([])
    end
  end
  
  describe '.enabled_categories' do
    it 'returns array of enabled category IDs' do
      category = Fabricate(:category)
      SiteSetting.mediabot_enabled_categories = category.id.to_s
      expect(described_class.enabled_categories).to eq([category.id])
    end
    
    it 'returns empty array when no categories enabled' do
      SiteSetting.mediabot_enabled_categories = ''
      expect(described_class.enabled_categories).to eq([])
    end
  end
  
  describe '.should_process_topic?' do
    let(:topic) { create_movie_topic }
    
    it 'returns true for enabled topic' do
      SiteSetting.mediabot_enabled = true
      SiteSetting.mediabot_enabled_tags = 'movie'
      expect(described_class.should_process_topic?(topic)).to be true
    end
    
    it 'returns false when plugin is disabled' do
      SiteSetting.mediabot_enabled = false
      expect(described_class.should_process_topic?(topic)).to be false
    end
    
    it 'returns false when tag is not enabled' do
      SiteSetting.mediabot_enabled = true
      SiteSetting.mediabot_enabled_tags = 'tv'
      expect(described_class.should_process_topic?(topic)).to be false
    end
    
    it 'returns false when category is not enabled' do
      SiteSetting.mediabot_enabled = true
      SiteSetting.mediabot_enabled_tags = 'movie'
      SiteSetting.mediabot_enabled_categories = '999'
      expect(described_class.should_process_topic?(topic)).to be false
    end
  end
  
  describe '.should_process_post?' do
    let(:post) { create_movie_command_post }
    
    it 'returns true for movie command' do
      SiteSetting.mediabot_enabled = true
      expect(described_class.should_process_post?(post)).to be true
    end
    
    it 'returns true for tv command' do
      post = create_tv_command_post
      SiteSetting.mediabot_enabled = true
      expect(described_class.should_process_post?(post)).to be true
    end
    
    it 'returns false when plugin is disabled' do
      SiteSetting.mediabot_enabled = false
      expect(described_class.should_process_post?(post)).to be false
    end
    
    it 'returns false for non-command post' do
      post.update(raw: 'The Iron Claw (2023)')
      SiteSetting.mediabot_enabled = true
      expect(described_class.should_process_post?(post)).to be false
    end
  end
end 