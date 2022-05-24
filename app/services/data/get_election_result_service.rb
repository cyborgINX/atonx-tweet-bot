require 'watir'
require 'webdrivers'
require 'pry'

KATHMANDU_METROPOLITAN = 'Kathmandu Metropolitan'

module ElectionData
  class GetElectionResultService

    def initialize
      @url = ENV['DATA_SOURCE']
      @browser = Watir::Browser.new :chrome, headless: true
    end

    def process
      @browser.goto(@url)
      sleep(1)
      election_place = @browser.header(class: 'election-header')&.h2(class: 'header-title')&.text
      return if election_place != KATHMANDU_METROPOLITAN

      nominees_collection = @browser.div(class: "nominee-list-group")&.ul(class: 'list-group')&.lis(class: 'election-list')
      return if nominees_collection.size.zero?

      top_3_candidates_coll = nominees_collection.to_a.first(3)
      extracted_result_arr = extract_data(top_3_candidates_coll)
      @browser.close
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
  end
end
