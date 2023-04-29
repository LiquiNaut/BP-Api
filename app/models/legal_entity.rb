# frozen_string_literal: true

class LegalEntity < ApplicationRecord
  has_many :addresses

  validates :ico, presence: true, uniqueness: true
  # dopisane , allow_blank: true do mena + periezviska na zaklade chyby
  validates :first_name, presence: true, allow_blank: true
  validates :last_name, presence: true, allow_blank: true
  validates :entity_name, presence: true


end

