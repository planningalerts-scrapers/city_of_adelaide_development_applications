require 'scraperwiki'
require 'rubygems'
require 'mechanize'


def scrape_table(agent, scrape_url)
  puts "Scraping " + scrape_url
  doc = agent.get(scrape_url)
  texts = doc.search('.text').map { |e| e.inner_text.strip }
  bldtexts = doc.search('.bldtxt').map { |e| e.inner_text.strip }
  reference = texts[0]
  on_notice_to = Date.strptime(bldtexts.last, '%e %b %Y').to_s rescue nil
  puts "Invalid date: #{bldtexts.last.inspect}" unless on_notice_to

  record = {
    'info_url' => 'http://dmzweb.adelaidecitycouncil.com/devapp/' + scrape_url,
    'comment_url' => 'mailto:d.planner@adelaidecitycouncil.com?subject=' + CGI::escape("Development Application Enquiry: " + reference),
    'council_reference' =>  reference,
    'on_notice_to' => on_notice_to,
    'address' => texts[1],
    'description' => texts[2],
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
doc = agent.get('http://dmzweb.adelaidecitycouncil.com/devapp/devapplist.asp')
doc.search('a').each do |a|
  if a["href"] && a["href"] != "#top"
    scrape_table(agent,  a["href"])
  end
end
