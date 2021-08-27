desc "This task is called by the Heroku scheduler add-on"
task :send_train_message => :environment do
  require 'line/bot'  # gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }

  users = User.includes(:trains)
  users.each do |user|
    train_status = YahooTrainService.train_status(user.trains)
    train_message = ''
    train_status.each do |status|
      train_message.concat("\n#{status[:name]}\n#{status[:text]}\n")
    end

    # if user.trains.present? && train_status.map { |i| i[:boolean] }.all?
    if user.trains.present? && train_status.map { |i| i[:boolean] }.any?
      # 発信するメッセージの設定
      push =
      "運行状況のお知らせだよ！\n今日は電車が遅れてるみたい(> <)#{train_message}詳しくはこれをみてね！\nhttps://transit.yahoo.co.jp/traininfo/area/4/\n今日も一日無理せず頑張ってください(^ ^)"
      # メッセージの発信先idを配列で渡す必要があるため、userテーブルよりpluck関数を使ってidを配列で取得
      user_id = user.line_id
      message = {
        type: 'text',
        text: push
      }
      response = client.multicast(user_id, message)
    end
  end
  "OK"
end

