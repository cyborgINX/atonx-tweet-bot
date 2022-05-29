require 'figaro'
require 'twitter'
require 'pry'

Figaro.application = Figaro::Application.new(
  environment: 'production',
  path: File.expand_path('config/application.yml')
)
Figaro.load

module AtonxTweetBot
  class TweetResultService
    attr_reader :config

    def initialize
      @config = twitter_api_config
    end

    def process(data, type)
      puts data
      case type
        when 'tweet'
          rest_client = configure_rest_client
          rest_client.update(data)
        else
          # TODO :  add more cases
      end
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
  end
end
