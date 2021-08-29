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


    events.each do |event|
      line_id = event['source']['userId']

      case event
        
      when Line::Bot::Event::Message # メッセージが送信された場合の対応（機能①）
        user = User.find_by(line_id: line_id) || User.create(line_id: line_id)
        
        unless event.type == Line::Bot::Event::MessageType::Text
          push = "テキスト以外はわからないよ〜(；；)" 
          message = {
            type: 'text',
            text: push
          }
          client.reply_message(event['replyToken'], message)
          head :ok
        end and return

        # ユーザーからテキスト形式のメッセージが送られて来た場合
        received_text = event.message['text']
        TextResponseService.message(received_text, user, client, event)
      when Line::Bot::Event::Follow # LINEお友達追された場合（機能②）
        User.create(line_id: line_id)
      when Line::Bot::Event::Unfollow# LINEお友達解除された場合（機能③）
        User.find_by(line_id: line_id).destroy
      end
    end
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
