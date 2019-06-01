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

from = page.form.field_with(name: /FromDatePicker/)
to = page.form.field_with(name: /ToDatePicker/)

from_date = Date.new(ENV["MORPH_PERIOD"].to_i, 1, 1)
from.value = from_date.strftime("%d/%m/%Y")

to_date = Date.new(ENV["MORPH_PERIOD"].to_i + 1, 1, 1).prev_day
# By default the to date is set to today's date. We can't use a later date
# otherwise the search doesn't work
if to_date < Date.strptime(to.value, "%d/%m/%Y")
  to.value = to_date.strftime("%d/%m/%Y")
end

EpathwayScraper::Page::Search.click_search(page)

EpathwayScraper::Page::Index.scrape_all_index_pages(nil, scraper.base_url, scraper.agent) do |record|
  # Do some last-minute tweaking of the address and description
  # fine tuning 'address' field, remove 'building name'
  if record["address"].split(',').size >= 3
    record["address"] = record["address"].split(',', 2)[1].strip
  end
  record["description"]= record["description"].gsub("\n", '. ').squeeze(' ')

  EpathwayScraper.save(record)
end
