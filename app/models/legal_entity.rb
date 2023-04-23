# frozen_string_literal: true
class LegalEntity < ApplicationRecord

  has_many :addresses

  # has_many :activities

  validates :ico, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :entity_name, presence: true


end

