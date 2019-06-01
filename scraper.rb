require "epathway_scraper"

ENV['MORPH_PERIOD'] ||= DateTime.now.year.to_s

puts "Getting data in year '" + ENV['MORPH_PERIOD'].to_s + "', changable via MORPH_PERIOD environment"

scraper = EpathwayScraper::Scraper.new(
  "https://epathway.adelaidecitycouncil.com/epathway/ePathwayProd"
)

page = scraper.agent.get(scraper.base_url)
page = EpathwayScraper::Page::ListSelect.follow_javascript_redirect(page, scraper.agent)
page = EpathwayScraper::Page::ListSelect.pick(page, :all)

page = EpathwayScraper::Page::Search.click_date_search_tab(page, scraper.agent)

EpathwayScraper::Page::DateSearch.pick_date_range(
  page,
  Date.new(ENV["MORPH_PERIOD"].to_i, 1, 1),
  Date.new(ENV["MORPH_PERIOD"].to_i + 1, 1, 1).prev_day
)

EpathwayScraper::Page::Index.scrape_all_index_pages(nil, scraper.base_url, scraper.agent) do |record|
  # Do some last-minute tweaking of the address and description
  # fine tuning 'address' field, remove 'building name'
  if record["address"].split(',').size >= 3
    record["address"] = record["address"].split(',', 2)[1].strip
  end
  record["description"]= record["description"].gsub("\n", '. ').squeeze(' ')

  EpathwayScraper.save(record)
end
