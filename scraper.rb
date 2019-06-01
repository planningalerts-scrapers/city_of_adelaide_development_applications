require "epathway_scraper"

ENV['MORPH_PERIOD'] ||= DateTime.now.year.to_s
year = ENV["MORPH_PERIOD"].to_i

puts "Getting data in year '#{year}', changable via MORPH_PERIOD environment"

EpathwayScraper.scrape(
  "https://epathway.adelaidecitycouncil.com/epathway/ePathwayProd",
  list_type: :all_year, year: year
) do |record|
  # fine tuning 'address' field, remove 'building name'
  if record["address"].split(',').size >= 3
    record["address"] = record["address"].split(',', 2)[1].strip
  end

  EpathwayScraper.save(record)
end
