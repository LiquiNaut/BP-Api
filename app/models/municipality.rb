# frozen_string_literal: true

class Municipality < ApplicationRecord

  has_one :address

  validates :codelist_code, presence: true, allow_blank: true
  validates :code, presence: true, allow_blank: true
  validates :name, presence: true

end

