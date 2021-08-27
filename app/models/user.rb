class User < ApplicationRecord
  has_many :trains, dependent: :destroy
end
