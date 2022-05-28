require 'figaro'
require 'twitter'
require 'pry'
require_relative 'get_election_result_service'

Figaro.application = Figaro::Application.new(
  environment: 'production',
  path: File.expand_path('config/application.yml')
)
Figaro.load

module ElectionData
  class TweetElectionResultService
    attr_reader :config

    def initialize
      @config = twitter_api_config
    end

    def perform
      client = configure_rest_client
      tweet_result(client)
    end

    private

    def twitter_api_config
      {
        consumer_key: ENV['CONSUMER_KEY'],
        consumer_secret: ENV['CONSUMER_SECRET'],
        access_token: ENV['ACCESS_TOKEN'],
        access_token_secret: ENV['ACCESS_TOKEN_SECRET']
      }
    end

    def configure_rest_client
      puts 'Configuring REST Client!'

      Twitter::REST::Client.new(config)
    end

    def tweet_result(client)
      get_election_data = GetElectionResultService.new.process
      mayor_hashtags = associated_hashtags("mayor")
      mayor_result_tweet_format = tweet_template(get_election_data, "Kathmandu Metropolitan", "mayor", mayor_hashtags)
      puts mayor_result_tweet_format
      client.update(mayor_result_tweet_format)
    end
    
    def tweet_template(data, location, position, hashtags)
      "#{location} - #{position.capitalize} Update - Election 2079" + "\n\n" +
        "1. \"#{data[0][1]}\" - \"#{data[0][0]}\" = \"#{data[0][2].to_i}\"" +  "\n" +
        "2. \"#{data[1][1]}\" - \"#{data[1][0]}\" = \"#{data[1][2].to_i}\"" + "\n" +
        "3. \"#{data[2][1]}\" - \"#{data[2][0]}\" = \"#{data[2][2].to_i}\"" + "\n\n" +
        "#{hashtags}"
    end

    def associated_hashtags(position)
      if position == "mayor"
        "#BalenShah #KathmanduMayor #LocalElections2022"
      end
    end
  end
end

ElectionData::TweetElectionResultService.new.perform
