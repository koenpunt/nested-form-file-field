class User < ApplicationRecord
  has_one :restaurant
  accepts_nested_attributes_for :restaurant
  validates :email, format: { with: /\A[^@\s]+@([^@\s]+\.)+[^@\W]+\z/ }, presence: true
end
