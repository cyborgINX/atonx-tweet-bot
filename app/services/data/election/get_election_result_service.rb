require 'watir'
require 'webdrivers'
require 'pry'
require 'figaro'
require 'twitter'

KATHMANDU_METROPOLITAN = 'Kathmandu Metropolitan'

Figaro.application = Figaro::Application.new(
  environment: 'production',
  path: File.expand_path('config/application.yml')
)
Figaro.load


module AtonxTweetBot
  class GetElectionResultService

    attr_reader :url, :browser, :config

    def initialize
      @url = ENV['DATA_SOURCE']
      @browser = Watir::Browser.new :chrome, headless: true
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
      get_election_data = process_election_data
      mayor_hashtags = associated_hashtags("mayor")
      mayor_result_tweet_format = tweet_template(get_election_data, "Kathmandu Metropolitan", "mayor", mayor_hashtags)
      puts mayor_result_tweet_format
      client.update(mayor_result_tweet_format)
    end

    def process_election_data
      browser.goto(url)
      sleep(1)
      election_place = browser.header(class: 'election-header')&.h2(class: 'header-title')&.text
      return if election_place != KATHMANDU_METROPOLITAN

      nominees_collection = browser.div(class: "nominee-list-group")&.ul(class: 'list-group')&.lis(class: 'election-list')
      return if nominees_collection.size.zero?

      top_3_candidates_coll = nominees_collection.to_a.first(2)
      extracted_result_arr = extract_data(top_3_candidates_coll)
      browser.close
      extracted_result_arr
    end

    def extract_data(candidates_coll)
      extracted_data_arr = []
      candidates_coll.each do |cc|
        candidate_list = cc.div(class: 'candidate-list')&.div(class: 'row')
        candidate_meta = candidate_list.div(class: 'candidate-meta')
        candidate_name = candidate_meta.div(class: 'candidate-name')&.text
        candidate_party_name = candidate_meta.div(class: 'candidate-party-name')&.text
        candidate_vote_num = candidate_list.div(class: "vote-numbers")&.text

        extracted_data_arr << [candidate_name, candidate_party_name, candidate_vote_num]
      end

      extracted_data_arr
    end

    def tweet_template(data, location, position, hashtags)
      "#{location} - #{position.capitalize} Update - Election 2079" + "\n\n" +
        "1. \"#{data[0][1]}\" - \"#{data[0][0]}\" = \"#{data[0][2].to_i}\"" +  "\n" +
        "2. \"#{data[1][1]}\" - \"#{data[1][0]}\" = \"#{data[1][2].to_i}\"" + "\n" +
        hashtags.to_s
    end

    def associated_hashtags(position)
      if position == "mayor"
        "#BalenShah #KathmanduMayor #LocalElections2022"
      end
    end
  end
end

AtonxTweetBot::GetElectionResultService.new.perform
