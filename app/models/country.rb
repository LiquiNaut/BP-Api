# frozen_string_literal: true

class Country < ApplicationRecord

  #namapovanie mena tabulky na model
  self.table_name = "countries"

  # :addresses, belongs_to bolo pred zmenou na has_many
  has_many :addresses, class_name: "Address"

  validates :codelist_code, presence: true
  validates :code, presence: true
  validates :name, presence: true

end

