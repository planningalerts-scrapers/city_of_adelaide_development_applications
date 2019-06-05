require "epathway_scraper"

EpathwayScraper.scrape_and_save(
  "https://epathway.adelaidecitycouncil.com/epathway/ePathwayProd",
  list_type: :all_this_year, state: "SA"
)
