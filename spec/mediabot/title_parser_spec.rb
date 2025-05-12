require 'rails_helper'

describe MediaBot::TitleParser do
  let(:topic) { Fabricate(:topic) }
  let(:post) { Fabricate(:post, topic: topic) }
  
  describe '#parse' do
    context 'with structured format' do
      it 'parses movie format correctly' do
        post.update(raw: '[movie] The Iron Claw (2023)')
        parser = described_class.new(post)
        result = parser.parse
        
        expect(result[:type]).to eq('movie')
        expect(result[:title]).to eq('The Iron Claw')
        expect(result[:year]).to eq('2023')
        expect(result[:is_inline]).to be false
      end
      
      it 'parses tv format correctly' do
        post.update(raw: '[tv] Breaking Bad (2008)')
        parser = described_class.new(post)
        result = parser.parse
        
        expect(result[:type]).to eq('tv')
        expect(result[:title]).to eq('Breaking Bad')
        expect(result[:year]).to eq('2008')
        expect(result[:is_inline]).to be false
      end
    end
    
    context 'with inline commands' do
      it 'parses !movie command correctly' do
        post.update(raw: '!movie The Iron Claw (2023)')
        parser = described_class.new(post)
        result = parser.parse
        
        expect(result[:type]).to eq('movie')
        expect(result[:title]).to eq('The Iron Claw')
        expect(result[:year]).to eq('2023')
        expect(result[:is_inline]).to be true
      end
      
      it 'parses !tv command correctly' do
        post.update(raw: '!tv Breaking Bad (2008)')
        parser = described_class.new(post)
        result = parser.parse
        
        expect(result[:type]).to eq('tv')
        expect(result[:title]).to eq('Breaking Bad')
        expect(result[:year]).to eq('2008')
        expect(result[:is_inline]).to be true
      end
    end
    
    context 'with tags' do
      it 'parses movie tag correctly' do
        topic.tags << Tag.find_or_create_by(name: 'movie')
        post.update(raw: 'The Iron Claw (2023)')
        parser = described_class.new(post)
        result = parser.parse
        
        expect(result[:type]).to eq('movie')
        expect(result[:title]).to eq('The Iron Claw')
        expect(result[:year]).to eq('2023')
        expect(result[:is_inline]).to be false
      end
      
      it 'parses tv tag correctly' do
        topic.tags << Tag.find_or_create_by(name: 'tv')
        post.update(raw: 'Breaking Bad (2008)')
        parser = described_class.new(post)
        result = parser.parse
        
        expect(result[:type]).to eq('tv')
        expect(result[:title]).to eq('Breaking Bad')
        expect(result[:year]).to eq('2008')
        expect(result[:is_inline]).to be false
      end
    end
  end
  
  describe '#should_process?' do
    context 'with inline commands' do
      it 'returns true for !movie command' do
        post.update(raw: '!movie The Iron Claw')
        parser = described_class.new(post)
        expect(parser.should_process?).to be true
      end
      
      it 'returns true for !tv command' do
        post.update(raw: '!tv Breaking Bad')
        parser = described_class.new(post)
        expect(parser.should_process?).to be true
      end
    end
    
    context 'with tags' do
      it 'returns true for enabled movie tag' do
        SiteSetting.mediabot_enabled_tags = 'movie,tv'
        topic.tags << Tag.find_or_create_by(name: 'movie')
        post.update(raw: 'The Iron Claw')
        parser = described_class.new(post)
        expect(parser.should_process?).to be true
      end
      
      it 'returns false for disabled tag' do
        SiteSetting.mediabot_enabled_tags = 'movie'
        topic.tags << Tag.find_or_create_by(name: 'tv')
        post.update(raw: 'Breaking Bad')
        parser = described_class.new(post)
        expect(parser.should_process?).to be false
      end
    end
    
    context 'with categories' do
      it 'returns true for enabled category' do
        SiteSetting.mediabot_enabled_categories = topic.category_id.to_s
        topic.tags << Tag.find_or_create_by(name: 'movie')
        post.update(raw: 'The Iron Claw')
        parser = described_class.new(post)
        expect(parser.should_process?).to be true
      end
      
      it 'returns false for disabled category' do
        SiteSetting.mediabot_enabled_categories = '999'
        topic.tags << Tag.find_or_create_by(name: 'movie')
        post.update(raw: 'The Iron Claw')
        parser = described_class.new(post)
        expect(parser.should_process?).to be false
      end
    end
  end
end 