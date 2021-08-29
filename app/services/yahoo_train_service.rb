class YahooTrainService
  require 'open-uri'
  require 'nokogiri'

  attr_reader :info

  def initialize(trains)
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
    @info = station_info
  end

  def message
    train_message = ''
    @info.each do |status|
      train_message.concat("\n#{status[:name]}\n#{status[:text]}\n")
    end
    train_message
  end

  def name_list
    train_name_list = ''
    @info.each do |status|
      train_name_list.concat("#{status[:name]}\n")
    end
    train_name_list
  end

  # 登録している路線の中にひとつでも遅延があるかどうか
  def delay?
    @info.map { |i| i[:boolean] }.any?
  end
end

# 要素ないが全てtrueかどうか
# info.map { |i| i[:boolean] }.all?
# 一つのみ
# info.map { |i| i[:boolean] }.any?
