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
      when Line::Bot::Event::Message # メッセージが送信された場合の対応
        user = User.find_by(line_id: line_id) || User.create(line_id: line_id)
        push = 
          event.type == Line::Bot::Event::MessageType::Text ? TextResponseService.new(event.message['text'], user).message : "テキスト以外はわからないよ〜(；；)"
        message = {
          type: 'text',
          text: push
        }
        client.reply_message(event['replyToken'], message)

      when Line::Bot::Event::Follow # LINEお友達追された場合
        User.create(line_id: line_id)

      when Line::Bot::Event::Unfollow# LINEお友達解除された場合
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
