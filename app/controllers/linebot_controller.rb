class LinebotController < ApplicationController
  require 'line/bot'  # gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'


  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      return head :bad_request
    end
    events = client.parse_events_from(body)
    events.each { |event|
      case event
        # メッセージが送信された場合の対応（機能①）
      when Line::Bot::Event::Message
        line_id = event['source']['userId']
        case event.type
          # ユーザーからテキスト形式のメッセージが送られて来た場合
        when Line::Bot::Event::MessageType::Text
          user = User.find_by(line_id: line_id)
          # event.message['text']：ユーザーから送られたメッセージ
          input = event.message['text']
          train_status = YahooTrainService.train_status(user.trains)
          train_message = ''
          train_status.each do |status|
            train_message.concat("\n#{status[:name]}\n#{status[:text]}\n")
          end
          case input
            # 「明日」or「あした」というワードが含まれる場合
          when /.*(今日|きょう|情報|じょうほう|遅延|ちえん).*/
            if train_status.map { |i| i[:boolean] }.any?
              push =
                "今日の運行状況？遅れてるみたい(> <)#{train_message}詳しくはこれをみてね！\nhttps://transit.yahoo.co.jp/traininfo/area/4/"
            else
              push =
              "今日の運行状況？今のところ大丈夫そうかな(^^)\n詳しくはこれをみてね！\nhttps://transit.yahoo.co.jp/traininfo/area/4/"
            end
          when /.*(https:\/\/transit.yahoo.co.jp\/traininfo\/detail\/).*/
            train_status = YahooTrainService.train_status(user.trains)
            train_name_list = ''
            train_status.each do |status|
              train_name_list.concat("#{status[:name]}\n")
            end
            train_list = user.trains.map(&:url)
            if train_list.include?(input)
              push =
                "その路線はもう登録してるよ(> <)\n今登録してる路線の一覧\n#{train_name_list}"
            else
              user.trains.create(url: input)
              push =
                "駅の情報を登録したよ(^ ^)\nこれであってるかな？\n#{input}\n間違ってたら削除って入力してから打ち直してください(> <)"
            end

          when /.*(登録|とうろく|一覧|いちらん).*/
            train_status = YahooTrainService.train_status(user.trains)
            train_name_list = ''
            train_status.each do |status|
              train_name_list.concat("#{status[:name]}\n")
            end
            if train_name_list.present?
              push =
                "今登録してる路線はこれだよ\n(^ ^)\n#{train_name_list}"
            else
              push =
              "今登録してる路線は特にないかな(> <)"
            end

          when /.*(使い方|つかいかた).*/
            push =
            "最初に路線の情報を教えてください。\nhttps://transit.yahoo.co.jp/traininfo/area/4/\nこの中にある路線から普段使っている路線のURLをそのまま送ってください。\n例えば、山手線なら\nhttps://transit.yahoo.co.jp/traininfo/detail/21/0/\nといった感じです。\n登録し路線に遅延があった場合は毎朝8じごろに遅延情報を送ります。\nまた、今日と送っていただければ、今の遅延情報を送ります。\n登録した路線を消したい場合は削除と送っていただければ、登録した路線を全て削除できます。\n何か不具合がありましたら、オーナーまでお問い合わせください。"

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
            if train_status.map { |i| i[:boolean] }.all?
              push =
                "今日の運行状況？遅れてるみたい(> <)#{train_message}詳しくはこれをみてね！\nhttps://transit.yahoo.co.jp/traininfo/area/4/"
            else
              push =
              "今日の運行状況？今のところ大丈夫そうかな(^^)\n詳しくはこれをみてね！\nhttps://transit.yahoo.co.jp/traininfo/area/4/"
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
        line_id = event['source']['userId']
        User.create(line_id: line_id)
        # LINEお友達解除された場合（機能③）
      when Line::Bot::Event::Unfollow
        # お友達解除したユーザーのデータをユーザーテーブルから削除
        line_id = event['source']['userId']
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
