require 'scraperwiki'
require 'rubygems'
require 'mechanize'

comment_url = 'mailto:council@burwood.nsw.gov.au?subject='
starting_url = 'https://ecouncil.burwood.nsw.gov.au/eservice/daEnquiry/currentlyAdvertised.do?function_id=588&orderBy=suburb&nodeNum=224'
search_result_url = 'https://ecouncil.burwood.nsw.gov.au/eservice/daEnquiryDetails.do?index='

def scrape_table(agent, scrape_url, comment_url)
  puts "Scraping " + scrape_url
  doc = agent.get(scrape_url)
  rows = doc.search('.inputField').map { |e| e.inner_text.strip }
  reference = rows[2]
  date_received = Date.strptime(rows[3], '%d/%m/%Y').to_s rescue nil
  puts "Invalid date: #{rows[3].inspect}" unless date_received

  record = {
    'info_url' => "https://ecouncil.burwood.nsw.gov.au/eservice/daEnquiryInit.do?doc_typ=10&nodeNum=219",
    'comment_url' => comment_url + CGI::escape("Development Application Enquiry: " + reference),
    'council_reference' => reference,
    'date_received' => date_received,
    'address' => rows[0],
    'description' => rows[1],
    'date_scraped' => Date.today.to_s
  }
  if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true) 
    ScraperWiki.save_sqlite(['council_reference'], record)
    puts "Saving " + reference
  else
    puts "Skipping already saved record " + reference
  end
end

agent = Mechanize.new

# Grab the starting page and go into each link to get a more reliable data format.
doc = agent.get(starting_url)
(0..doc.search('.non_table_headers').size - 1).each do |i|
  scrape_url = search_result_url + i.to_s
  scrape_table(agent, scrape_url, comment_url)
end
