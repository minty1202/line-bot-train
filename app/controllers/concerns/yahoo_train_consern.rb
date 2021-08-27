module YahooTrainConsern
  require 'open-uri'
  require 'nokogiri'


  def train_status(trains)
    station_info = []
    trains.each do |t|
      charset = nil
      html = open(t.url) do |f|
        charset = f.charset
        f.read
      end

      doc = Nokogiri::HTML.parse(html, nil, charset)

      doc.xpath('//div[@class="mainWrp"]').each do |node|
        station_info.push({
          name: node.css('h1').inner_text,
          text: node.css('dd p').inner_text,
          boolean: node.css('dd').to_s.include?('trouble')
        })
      end
    end
    station_info
  end
end