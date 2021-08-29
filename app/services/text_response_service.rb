class TextResponseService
  require 'line/bot'  # gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'


  def self.message(received_text, user, client, event)

    user_train_info = YahooTrainService.new(user.trains)
    case received_text
    when /.*(今日|きょう|情報|じょうほう|遅延|ちえん).*/
      # unless user.trains
      #   push = text_i18n('no_registered_list')
      #   message = {
      #     type: 'text',
      #     text: push
      #   }
      #   client.reply_message(event['replyToken'], message)
      #   head :ok
      # end and return
      if user_train_info.delay?
        push = text_i18n('late', user_train_info.message)
      else
        push = text_i18n('ok')
      end
    when /.*(https:\/\/transit.yahoo.co.jp\/traininfo\/detail\/).*/
      if user.url_is_registered?(received_text)
        push = text_i18n('already_registered', user_train_info.name_list)
      else
        new_train = user.trains.create(url: received_text)
        new_train = YahooTrainService.new([new_train])
        push = text_i18n('registered', new_train.info[0][:name])
      end
    when /.*(登録|とうろく|一覧|いちらん).*/
      if user.trains.present? 
        push = text_i18n('registered_list', user_train_info.name_list)
      else
        push = text_i18n('no_registered_list')
      end

    when /.*(使い方|つかいかた).*/
      push = text_i18n('usage')

    when /.*(削除|さくじょ|消去|しょうきょ).*/
      user.trains.destroy_all
      push = text_i18n('delete')

    when /.*(かわいい|可愛い|カワイイ|きれい|綺麗|キレイ|素敵|ステキ|すてき|面白い|おもしろい|ありがと|すごい|スゴイ|スゴい|好き|頑張|がんば|ガンバ).*/
      push = text_i18n('thanks')
    when /.*(こんにちは|こんばんは|初めまして|はじめまして|おはよう).*/
      push = text_i18n('hello')
    else # 該当しない文字列
      if user_train_info.delay?
        push = text_i18n('late_word_probably', user_train_info.message)
          

      else
        push = text_i18n('ok_word_probably')
      end
    end

    message = {
      type: 'text',
      text: push
    }
    client.reply_message(event['replyToken'], message)
  end

  private

  def self.text_i18n(message, user_info=nil)
    user_info ? I18n.t(message, user_info: user_info, scope: [:line_bot, :response]) : I18n.t(message, scope: [:line_bot, :response])
  end
end
