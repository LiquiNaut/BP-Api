# frozen_string_literal: true
class Address < ApplicationRecord
  belongs_to :legal_entity
  # namiesto has_one dam belongs_to, doplnil som optional true
  belongs_to :country
  # neviem ci je dobre to belongs_to municipality, doplnene optional true lebo id v municipality nemusi byt dostupne
  belongs_to :municipality

  validates :street, presence: true
  # pridana validacia regNumber z presence: true na numericality
  validates :reg_number,numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :building_number, presence: true
  validates :postal_code, presence: true

end

