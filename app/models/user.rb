class User < ApplicationRecord
  has_many :train, dependent: :destroy
end
