module YahooTrainConsern
  require 'open-uri'
  require 'nokogiri'

  YAHOO_DETAIL_BASE_URL='https://transit.yahoo.co.jp/traininfo/detail/'
  def train_status
    toubu_touzyou = '82/0/' # 東武東上線
    
    yamanote = '21/0/' # 山手線

    url = YAHOO_DETAIL_BASE_URL + toubu_touzyou

    charset = nil
    html = open(url) do |f|
      charset = f.charset
      f.read
    end

    doc = Nokogiri::HTML.parse(html, nil, charset)
    messages = []

    doc.xpath('//div[@class="mainWrp"]').each do |node|

      # puts node.css('h1').inner_text
      # puts node.css('dd p').inner_text
      # puts node.css('dd').to_s.include?('normal')
      messages.push(node.css('h1').inner_text, node.css('dd p').inner_text, node.css('dd').to_s.include?('trouble'))

    end
    p messages

    # @shops = @shops.drop(1)
    # p @shops

    # p doc.title
  end
end