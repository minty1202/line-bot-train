class User < ApplicationRecord
  has_many :trains, dependent: :destroy

  def url_is_registered?(url)
    !!trains.find_by(url: url)
  end
end
