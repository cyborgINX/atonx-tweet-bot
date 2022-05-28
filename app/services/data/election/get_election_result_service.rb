require 'watir'
require 'webdrivers'
require 'pry'
require_relative '../../tweet_result_service'

KATHMANDU_METROPOLITAN = 'Kathmandu Metropolitan'
MAYOR = 'mayor'

module AtonxTweetBot
  class GetElectionResultService
    attr_reader :url, :browser

    def initialize
      @url = ENV['DATA_SOURCE']
      @browser = Watir::Browser.new :chrome, headless: true
    end

    def perform
      get_election_data = extract_election_data
      return 'No data to tweet at this time. Please try again later!' if get_election_data.is_a? String

      rel_hashtags = associated_hashtags(MAYOR)
      res_tweet_format = tweet_template(get_election_data, KATHMANDU_METROPOLITAN, MAYOR, rel_hashtags)
      TweetResultService.new.process(res_tweet_format)
    end

    private

    def extract_election_data
      browser.goto(url)
      sleep(1)
      election_place = browser.header(class: 'election-header')&.h2(class: 'header-title')&.text
      return if election_place != KATHMANDU_METROPOLITAN

      nominees_div_collection = browser.div(class: 'nominee-list-group')&.ul(class: 'list-group')&.lis(class: 'election-list')
      return if nominees_div_collection.size.zero?

      int_div_siz = begin
        nominees_div_collection.size >= 3 ? 3 : nominees_div_collection.size
      rescue StandardError
        0
      end
      return 'No Data available.' if int_div_siz.zero?

      top_3_candidates_div_coll = nominees_div_collection.to_a.first(int_div_siz)
      extracted_result_arr = extract_top_data(top_3_candidates_div_coll)
      browser.close
      extracted_result_arr
    end

    def extract_top_data(candidates_div_coll)
      extracted_data_arr = []
      candidates_div_coll.each do |cc|
        candidate_list = cc.div(class: 'candidate-list')&.div(class: 'row')
        candidate_meta = candidate_list.div(class: 'candidate-meta')
        candidate_name = candidate_meta.div(class: 'candidate-name')&.text
        candidate_party_name = candidate_meta.div(class: 'candidate-party-name')&.text
        candidate_vote_num = candidate_list.div(class: 'vote-numbers')&.text

        extracted_data_arr << [candidate_name, candidate_party_name, candidate_vote_num]
      end

      extracted_data_arr
    end

    def tweet_template(data, location, position, hashtags)
      # TODO : Make this tweet template more robust.
      "#{location} - #{position.capitalize} Update - Election 2079" + "\n\n" +
        "1. \"#{data[0][1]}\" - \"#{data[0][0]}\" = \"#{data[0][2].to_i}\"" +  "\n" +
        "2. \"#{data[1][1]}\" - \"#{data[1][0]}\" = \"#{data[1][2].to_i}\"" + "\n" +
        hashtags.to_s
    end

    def associated_hashtags(position)
      '#BalenShah #KathmanduMayor #LocalElections2022' if position == 'mayor'
    end
  end
end

AtonxTweetBot::GetElectionResultService.new.perform
