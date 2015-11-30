namespace :assets do
  task :precompile do
    puts `bundle exec jekyll build`
  end
end

namespace :case do
  desc "Calculate a total count of cases from Maryland Case Search"
  task :count do
    require "pg"

    conn = PG.connect(ENV.fetch("DATABASE_URL","postgres://postgres@localhost/ottlaw_development"))
    result = conn.exec("SELECT count(1) FROM cases").first

    puts "#{result["count"]} cases!"
  end
end

namespace :collect do
  desc "Collect case information from Maryland Case Search"
  task :cases,[ :year ] do |_,args|
    require "active_support/core_ext/object/blank" # present?
    require "csv"
    require "mechanize"
    require_relative "collect/collected_case"

    ActiveRecord::Base.establish_connection(ENV.fetch("DATABASE_URL","postgres://postgres@localhost/ottlaw_development"))

    agent = Mechanize.new
    year = args[:year] || DateTime.now.year

    # Must agree to terms, conditions, and limitations to navigate to search page
    search_page = agent.post("http://casesearch.courts.state.md.us/casesearch/processDisclaimer.jis",
                             action: "Continue",
                             disclaimer: "Y")

    # Make search request to navigate to results page
    results_page = agent.post("http://casesearch.courts.state.md.us/casesearch/inquirySearch.jis",
                              action: "Search",
                              company: "N",
                              countyName: "",
                              courtSystem: "B",
                              exactMatchLn: "Y",
                              filingDate: "",
                              filingEnd: "12/31/#{year}",
                              filingStart: "1/1/#{year}",
                              firstName: "JASON",
                              lastName: "OTT",
                              middleName: "",
                              partyType: "ATN",  # ATTORNEY
                              site: "00")

    # Download tab delimited file
    csv_page = results_page.link_with(text: /Excel/).click

    # Parse tab delimited file
    csv = CSV.parse(csv_page.body,col_sep: "\t",
                                  headers: :first_row,
                                  header_converters: :symbol,
                                  return_headers: false)

    # Map parsed csv file to an array of hashes and bulk insert into database
    CollectedCase.create!(csv.map(&:to_h)) if csv.present?

    puts "Collected and stored #{csv.length} cases from #{year}."
  end
end
