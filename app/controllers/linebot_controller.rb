class LinebotController < ApplicationController
  require 'line/bot'  # gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  include YahooTrainConsern

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      return head :bad_request
    end
    events = client.parse_events_from(body)
    events.each { |event|
      case event
        line_id = event['source']['userId']
        # メッセージが送信された場合の対応（機能①）
      when Line::Bot::Event::Message
        case event.type
          # ユーザーからテキスト形式のメッセージが送られて来た場合
        when Line::Bot::Event::MessageType::Text
          user = User.find_by(line_id: line_id)
          puts 'aaaaaaaaaaaaaaaaa'
          # event.message['text']：ユーザーから送られたメッセージ
          input = event.message['text']
          case input
            # 「明日」or「あした」というワードが含まれる場合
          when /.*(今日|きょう).*/
            train_status = train_status(user.trains)
            train_message = ''
            train_status.each do |status|
              train_message.concat("\n#{status[:name]}\n#{status[:text]}\n")
            end
            if train_status.map { |i| i[:boolean] }.all?
              push =
                "今日の運行状況？遅れてるみたい(> <)#{train_message}詳しくはこれをみてね！\nhttps://transit.yahoo.co.jp/traininfo/area/4/"
            else
              push =
              "今日の運行状況？今のところ大丈夫そうかな(^^)\n詳しくはこれをみてね！\nhttps://transit.yahoo.co.jp/traininfo/area/4/#{train_message}"
            end

          when /.*(東部|とうぶ).*/
            user.trains.toubu_touzyou
            push =
              user.trains.to_s

          when /.*(山手|やまのて).*/
            user.trains.yamanote
            push =
              user.trains.to_s

          when /.*(削除|さくじょ|消去|しょうきょ).*/
            user.trains.destroy_all
            push =
              "登録してある路線を全部消したよ(> <)\nもう一度路線を登録してね"

          when /.*(かわいい|可愛い|カワイイ|きれい|綺麗|キレイ|素敵|ステキ|すてき|面白い|おもしろい|ありがと|すごい|スゴイ|スゴい|好き|頑張|がんば|ガンバ).*/
            push =
              "ありがとう！！！\n優しい言葉をかけてくれるあなたはとても素敵です(^^)"
          when /.*(こんにちは|こんばんは|初めまして|はじめまして|おはよう).*/
            push =
              "こんにちは。\n声をかけてくれてありがとう\n今日があなたにとっていい日になりますように(^^)"
          else # 該当しない文字列

            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              word =
                ["雨だけど元気出していこうね！",
                 "雨に負けずファイト！！",
                 "雨だけどあなたの明るさでみんなを元気にしてあげて(^^)"].sample
              push =
                "今日の天気？\n今日は雨が降りそうだから傘があった方が安心だよ。\n　  6〜12時　#{per06to12}％\n　12〜18時　 #{per12to18}％\n　18〜24時　#{per18to24}％\n#{word}"
            else
              word =
                ["天気もいいから一駅歩いてみるのはどう？(^^)",
                 "今日会う人のいいところを見つけて是非その人に教えてあげて(^^)",
                 "素晴らしい一日になりますように(^^)",
                 "雨が降っちゃったらごめんね(><)"].sample
              push =
                "今日の天気？\n今日は雨は降らなさそうだよ。\n#{word}"
            end
          end
          # テキスト以外（画像等）のメッセージが送られた場合
        else
          push = "テキスト以外はわからないよ〜(；；)"
        end
        
        message = {
          type: 'text',
          text: push
        }
        client.reply_message(event['replyToken'], message)
        # LINEお友達追された場合（機能②）
      when Line::Bot::Event::Follow
        # 登録したユーザーのidをユーザーテーブルに格納
        # line_id = event['source']['userId']
        User.create(line_id: line_id)
        # LINEお友達解除された場合（機能③）
      when Line::Bot::Event::Unfollow
        # お友達解除したユーザーのデータをユーザーテーブルから削除
        # line_id = event['source']['userId']
        User.find_by(line_id: line_id).destroy
      end
    }
    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
