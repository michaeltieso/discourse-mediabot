require 'rails_helper'

describe MediaBot::ReplyFormatter do
  let(:movie_data) do
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
    }
  end
  
  let(:tv_data) do
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
    }
  end
  
  describe '#format' do
    context 'with movie data' do
      it 'formats movie data correctly' do
        formatter = described_class.new(movie_data, 'movie')
        result = formatter.format
        
        expect(result).to include('🎬 **The Iron Claw (2023)**')
        expect(result).to include('The true story of the inseparable Von Erich brothers...')
        expect(result).to include('⭐️ Rating: 7.9')
        expect(result).to include('⏱ Runtime: 132 minutes')
        expect(result).to include('👥 Cast: Zac Efron, Jeremy Allen White')
        expect(result).to include('🎭 Genres: Drama, Biography')
      end
      
      it 'handles missing data gracefully' do
        movie_data.delete('overview')
        movie_data.delete('poster_path')
        
        formatter = described_class.new(movie_data, 'movie')
        result = formatter.format
        
        expect(result).to include('🎬 **The Iron Claw (2023)**')
        expect(result).not_to include('Overview:')
        expect(result).not_to include('Poster:')
      end
    end
    
    context 'with tv data' do
      it 'formats tv data correctly' do
        formatter = described_class.new(tv_data, 'tv')
        result = formatter.format
        
        expect(result).to include('📺 **Breaking Bad (2008)**')
        expect(result).to include('A high school chemistry teacher turned methamphetamine manufacturer...')
        expect(result).to include('⭐️ Rating: 9.5')
        expect(result).to include('⏱ Runtime: 45 minutes')
        expect(result).to include('👥 Cast: Bryan Cranston, Aaron Paul')
        expect(result).to include('🎭 Genres: Drama, Crime')
      end
      
      it 'handles missing data gracefully' do
        tv_data.delete('overview')
        tv_data.delete('poster_path')
        
        formatter = described_class.new(tv_data, 'tv')
        result = formatter.format
        
        expect(result).to include('📺 **Breaking Bad (2008)**')
        expect(result).not_to include('Overview:')
        expect(result).not_to include('Poster:')
      end
    end
  end
  
  describe '#format_cast' do
    it 'limits cast to 5 members' do
      movie_data['credits']['cast'] = (1..10).map do |i|
        { 'name' => "Actor #{i}", 'character' => "Character #{i}" }
      end
      
      formatter = described_class.new(movie_data, 'movie')
      result = formatter.send(:format_cast)
      
      expect(result).to eq('👥 Cast: Actor 1, Actor 2, Actor 3, Actor 4, Actor 5')
    end
    
    it 'handles empty cast' do
      movie_data['credits']['cast'] = []
      
      formatter = described_class.new(movie_data, 'movie')
      result = formatter.send(:format_cast)
      
      expect(result).to be_nil
    end
  end
  
  describe '#format_genres' do
    it 'formats genres correctly' do
      formatter = described_class.new(movie_data, 'movie')
      result = formatter.send(:format_genres)
      
      expect(result).to eq('🎭 Genres: Drama, Biography')
    end
    
    it 'handles empty genres' do
      movie_data['genres'] = []
      
      formatter = described_class.new(movie_data, 'movie')
      result = formatter.send(:format_genres)
      
      expect(result).to be_nil
    end
  end
end 