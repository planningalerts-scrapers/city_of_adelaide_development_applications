require 'scraperwiki'
require 'mechanize'

def is_valid_year(date_str, min=2006, max=DateTime.now.year)
  if ( date_str.scan(/^(\d)+$/) )
    if ( (min..max).include?(date_str.to_i) )
      return true
    end
  end
  return false
end

unless ( is_valid_year(ENV['MORPH_PERIOD'].to_s) )
  ENV['MORPH_PERIOD'] = DateTime.now.year.to_s
end
puts "Getting data in year '" + ENV['MORPH_PERIOD'].to_s + "', changable via MORPH_PERIOD environment"

cookie_url = "https://epathway.adelaidecitycouncil.com/ePathway/ePathwayProd/Web/default.aspx"
search_url = "https://epathway.adelaidecitycouncil.com/epathway/ePathwayProd/web/GeneralEnquiry/externalrequestbroker.aspx?Module=EGELAP&Class=DEVT&Type=DEVT"
base_url   = "https://epathway.adelaidecitycouncil.com/epathway/ePathwayProd/web/GeneralEnquiry/"
daTypes = ['DA', 'S49', 'S10', 'HIS', 'LD']

agent = Mechanize.new
agent.user_agent_alias = 'Mac Safari'

# select Planning Application
page = agent.get cookie_url
page = agent.get search_url

# local DB lookup if DB exist and find out what is the maxDA number
def dbLookup(type = 'DA')
  i = 1;
  sql = "select * from data where `council_reference` like '#{type}%/#{ENV['MORPH_PERIOD']}'"
  results = ScraperWiki.sqliteexecute(sql) rescue false
  if ( results )
    results.each do |result|
      maxApplication = result['council_reference'].gsub!(type + '/', '').gsub!("/#{ENV['MORPH_PERIOD']}", '')
      if maxApplication.to_i > i
        i = maxApplication.to_i
      end
    end
  end
  maxApplication = i
end

daTypes.each do |type|
  puts "Going to scrape '#{type}' type of applications"

  maxApplication = dbLookup(type)
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
