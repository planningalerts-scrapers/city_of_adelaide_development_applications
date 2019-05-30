require "epathway_scraper"

ENV['MORPH_PERIOD'] ||= DateTime.now.year.to_s

puts "Getting data in year '" + ENV['MORPH_PERIOD'].to_s + "', changable via MORPH_PERIOD environment"

scraper = EpathwayScraper::Scraper.new(
  "https://epathway.adelaidecitycouncil.com/epathway/ePathwayProd"
)

cookie_url = "https://epathway.adelaidecitycouncil.com/ePathway/ePathwayProd/Web/default.aspx"
search_url = "https://epathway.adelaidecitycouncil.com/epathway/ePathwayProd/web/GeneralEnquiry/externalrequestbroker.aspx?Module=EGELAP&Class=DEVT&Type=DEVT"
base_url   = "https://epathway.adelaidecitycouncil.com/epathway/ePathwayProd/web/GeneralEnquiry/"
daTypes = ['DA', 'S49', 'S10', 'HIS', 'LD']

agent = scraper.agent

# select Planning Application
page = agent.get cookie_url
page = agent.get search_url

daTypes.each do |type|
  puts "Going to scrape '#{type}' type of applications"

  maxApplication = 1
  error = 0
  while error < 10 do
    form = page.form
    form.field_with(:name=>'ctl00$MainBodyContent$mGeneralEnquirySearchControl$mTabControl$ctl04$mFormattedNumberTextBox').value = type + '/' + maxApplication.to_s + '/' + ENV['MORPH_PERIOD'].to_s
    button = form.button_with(:value => "Search")
    list = form.click_button(button)

    count = 0
    EpathwayScraper::Page::Index.scrape_index_page(list, scraper.base_url, scraper.agent) do |record|
      count += 1
      # Do some last-minute tweaking of the address and description
      # fine tuning 'address' field, remove 'building name'
      if record["address"].split(',').size >= 3
        record["address"] = record["address"].split(',', 2)[1].strip
      end
      record["description"]= record["description"].gsub("\n", '. ').squeeze(' ')

      EpathwayScraper.save(record)
    end

    if count == 0
      error += 1
    else
      error  = 0
    end

    # increase maxApplication value and scan the next DA
    maxApplication += 1
  end
end
