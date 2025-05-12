require 'rails_helper'

describe Jobs::MediaBotReply do
  let(:topic) { Fabricate(:topic) }
  let(:post) { Fabricate(:post, topic: topic) }
  let(:movie_data) do
    {
      'title' => 'The Iron Claw',
      'year' => '2023',
      'overview' => 'The true story of the inseparable Von Erich brothers...'
    }
  end
  
  before do
    SiteSetting.mediabot_enabled = true
    SiteSetting.mediabot_tmdb_api_key = 'test_tmdb_key'
    SiteSetting.mediabot_tvdb_api_key = 'test_tvdb_key'
  end
  
  describe '#execute' do
    it 'creates a reply post' do
      topic.tags << Tag.find_or_create_by(name: 'movie')
      post.update(raw: 'The Iron Claw (2023)')
      
      allow_any_instance_of(MediaBot::Fetcher).to receive(:fetch).and_return(movie_data)
      
      expect { subject.execute(topic_id: topic.id) }.to change { Post.count }.by(1)
      
      reply = Post.last
      expect(reply.topic_id).to eq(topic.id)
      expect(reply.raw).to include('The Iron Claw')
      expect(reply.raw).to include('The true story of the inseparable Von Erich brothers...')
    end
    
    it 'does not create a reply if disabled' do
      SiteSetting.mediabot_enabled = false
      topic.tags << Tag.find_or_create_by(name: 'movie')
      post.update(raw: 'The Iron Claw (2023)')
      
      expect { subject.execute(topic_id: topic.id) }.not_to change { Post.count }
    end
    
    it 'does not create a reply for non-first post' do
      topic.tags << Tag.find_or_create_by(name: 'movie')
      Fabricate(:post, topic: topic, raw: 'The Iron Claw (2023)')
      
      expect { subject.execute(topic_id: topic.id) }.not_to change { Post.count }
    end
    
    it 'handles API errors gracefully' do
      topic.tags << Tag.find_or_create_by(name: 'movie')
      post.update(raw: 'The Iron Claw (2023)')
      
      allow_any_instance_of(MediaBot::Fetcher).to receive(:fetch).and_raise(MediaBot::Fetcher::ApiError)
      
      expect { subject.execute(topic_id: topic.id) }.not_to raise_error
      expect(Post.last.raw).to include('Error fetching media information')
    end
  end
end 