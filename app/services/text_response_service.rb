class TextResponseService
  attr_reader :received_text
  attr_reader :user

  def initialize(received_text, user)
    @received_text = received_text
    @user = user
  end

  def message
    user_train_info = YahooTrainService.new(user.trains)
    case received_text
    when /.*(今日|きょう|情報|じょうほう|遅延|ちえん).*/
      return text_i18n('no_registered_list') if user.trains.blank?

      user_train_info.delay? ? text_i18n('late', user_train_info.message) : text_i18n('ok')

    when /.*(https:\/\/transit.yahoo.co.jp\/traininfo\/detail\/).*/
      user.url_is_registered?(received_text) ? text_i18n('already_registered', user_train_info.name_list) : text_i18n('registered', user_train_registration.info[0][:name])

    when /.*(登録|とうろく|一覧|いちらん).*/
      user.trains.present? ? text_i18n('registered_list', user_train_info.name_list) : text_i18n('no_registered_list')

    when /.*(使い方|つかいかた).*/
      text_i18n('usage')

    when /.*(削除|さくじょ|消去|しょうきょ).*/
      user.trains.destroy_all
      text_i18n('delete')

    when /.*(かわいい|可愛い|カワイイ|きれい|綺麗|キレイ|素敵|ステキ|すてき|面白い|おもしろい|ありがと|すごい|スゴイ|スゴい|好き|頑張|がんば|ガンバ).*/
      text_i18n('thanks')

    when /.*(こんにちは|こんばんは|初めまして|はじめまして|おはよう).*/
      text_i18n('hello')

    else # 該当しない文字列
      user_train_info.delay? ? text_i18n('late_word_probably', user_train_info.message) : text_i18n('ok_word_probably')
    end
  end

  private

  def text_i18n(message, user_info=nil)
    user_info ? I18n.t(message, user_info: user_info, scope: [:line_bot, :response]) : I18n.t(message, scope: [:line_bot, :response])
  end

  def user_train_registration
    new_train = user.trains.create(url: received_text)
    YahooTrainService.new([new_train])
  end
end
