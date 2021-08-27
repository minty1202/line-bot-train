class Train < ApplicationRecord
  YAHOO_DETAIL_BASE_URL='https://transit.yahoo.co.jp/traininfo/detail/'.freeze
  # toubu_touzyou = '82/0/' # 東武東上線
  # yamanote = '21/0/' # 山手線

  class << self

    # 東武東上線
    def toubu_touzyou
      create(url: YAHOO_DETAIL_BASE_URL + '82/0/')
    end

    # 山手線
    def yamanote
      create(url: YAHOO_DETAIL_BASE_URL + '21/0/')
    end
  end
end
