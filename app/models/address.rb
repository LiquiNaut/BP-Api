# frozen_string_literal: true

class Address < ApplicationRecord

  belongs_to :legal_entity, class_name: 'LegalEntity'

  belongs_to :country, class_name: 'Country'
  # doplnene optional true lebo id v municipality nemusi byt dostupne
  belongs_to :municipality, class_name: 'Municipality'

  # nasiel sa v jsone udaj ktory neobsahuje atribut street, preto , allow_blank: true
  validates :street, presence: true, allow_blank: true
  # pridana validacia regNumber z presence: true na numericality
  validates :reg_number, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  # nasiel sa v jsone udaj ktory neobsahuje atribut buidlingNumber, preto , allow_blank: true
  validates :building_number, presence: true, allow_blank: true
  # nasiel sa v jsone udaj ktory neobsahuje atribut postalCode, preto , allow_blank: true
  validates :postal_code, presence: true, allow_blank: true

end

