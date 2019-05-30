require "epathway_scraper"

ENV['MORPH_PERIOD'] ||= DateTime.now.year.to_s

puts "Getting data in year '" + ENV['MORPH_PERIOD'].to_s + "', changable via MORPH_PERIOD environment"

cookie_url = "https://epathway.adelaidecitycouncil.com/ePathway/ePathwayProd/Web/default.aspx"
search_url = "https://epathway.adelaidecitycouncil.com/epathway/ePathwayProd/web/GeneralEnquiry/externalrequestbroker.aspx?Module=EGELAP&Class=DEVT&Type=DEVT"
base_url   = "https://epathway.adelaidecitycouncil.com/epathway/ePathwayProd/web/GeneralEnquiry/"
daTypes = ['DA', 'S49', 'S10', 'HIS', 'LD']

agent = Mechanize.new

# select Planning Application
page = agent.get cookie_url
page = agent.get search_url

daTypes.each do |type|
  puts "Going to scrape '#{type}' type of applications"

  maxApplication = 1
  error = 0
  cont = true
  while cont do
    form = page.form
    form.field_with(:name=>'ctl00$MainBodyContent$mGeneralEnquirySearchControl$mTabControl$ctl04$mFormattedNumberTextBox').value = type + '/' + maxApplication.to_s + '/' + ENV['MORPH_PERIOD'].to_s
    button = form.button_with(:value => "Search")
    list = form.click_button(button)

    table = list.search("table.ContentPanel")
    unless ( table.empty? )
      error  = 0
      tr     = table.search("tr.ContentPanel")

      # fine tuning 'address' field, remove 'building name'
      address = tr.search('span')[1].inner_text.strip
      if address.split(',').size >= 3
        address = address.split(',', 2)[1].strip
      end

      record = {
        'council_reference' => tr.search('a').inner_text,
        'address'           => address,
        'description'       => tr.search('span')[2].inner_text.gsub("\n", '. ').squeeze(' '),
        'info_url'          => base_url + tr.search('a')[0]['href'],
        'date_scraped'      => Date.today.to_s,
        'date_received'     => Date.parse(tr.search('span')[0].inner_text).to_s,
      }

      puts "Saving record " + record['council_reference'] + ", " + record['address']
#         puts record
      ScraperWiki.save_sqlite(['council_reference'], record)
    else
      error += 1
    end

    # increase maxApplication value and scan the next DA
    maxApplication += 1
    if error == 10
      cont = false
    end
  end
end
