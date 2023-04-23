class RpoBatchInit

  require 'open-uri'
  require 'rubygems/package'
  require 'json'
  require 'zlib'
  require 'fileutils'
  require 'date'
  # require 'byebug'


  def self.perform
=begin
    today = Date.today.strftime('%Y-%m-%d')
    url = "https://frkqbrydxwdp.compat.objectstorage.eu-frankfurt-1.oraclecloud.com/susr-rpo/batch-daily/actual_#{today}.json.gz"

    # Získame názov súboru
    filename = "actual_#{today}.json.gz"

    # Stiahneme súbor z URL
    File.open(File.basename(filename), 'wb') do |saved_file|
      # Prevzorkujeme súbor pomocou Net::HTTP
      response = Net::HTTP.get_response(URI.parse(url))
      # Zapíšeme súbor na disk v binárnom móde
      saved_file.write(Zlib::GzipReader.new(StringIO.new(response.body)).read)
    end

    puts "Súbor #{filename} bol úspešne stiahnutý."

    # Stiahne súbor
    uri = URI(url)
    response = Net::HTTP.get_response(uri)

    # Uloží súbor
    File.open(filename, "wb") do |saved_file|
      saved_file.write(response.body)
    end
=end

=begin
    buffer_size = 1024 * 1024 # Veľkosť buffera nastavená na 1 MB
    directory_name = "batch-init"

    # Vytvorenie priečinka, ak neexistuje
    FileUtils.mkdir_p(directory_name)

    # Zisti datum prvej soboty mesiaca
    def first_saturday_of_month(year, month)
      date = Date.new(year, month, 1)
      date += (6 - date.wday) % 7
      date.strftime('%Y-%m-%d')
    end

    today = Date.today
    first_saturday = first_saturday_of_month(today.year, today.month)

    (1..21).each do |i|
      file_number = format('%03d', i) # Formátuj číslo súboru na 3 číslice s nulami
      url = "https://frkqbrydxwdp.compat.objectstorage.eu-frankfurt-1.oraclecloud.com/susr-rpo/batch-init/init_#{first_saturday}_#{file_number}.json.gz"

      compressed_file = "#{directory_name}/#{first_saturday}_#{file_number}.json.gz"
      output_file = "#{directory_name}/#{first_saturday}_#{file_number}.json"

      # Stiahnutie súboru
      File.open(compressed_file, 'wb') do |local_file|
        URI.open(url, 'rb', :content_length_proc => lambda { |content_length| }) do |remote_file|
          while (buffer = remote_file.read(buffer_size))
            local_file.write(buffer)
          end
        end
      end

      # Dekompresia súboru
      Zlib::GzipReader.open(compressed_file) do |gz|
        File.open(output_file, 'wb') do |file|
          file.write(gz.read)
        end
      end

      # Zmazanie komprimovaných suborov
      # File.delete(compressed_file)

      puts "Súbor č. #{file_number} bol úspešne stiahnutý, dekompresovaný a uložený ako #{output_file}."
    end
=end

    # filename = Rails.root.join('batch-init', '2023-04-01_001.json.gz')
    filename = Rails.root.join('batch-init', 'results-test.json.gz')
    # Otvorí a deserializuje súbor
    deserialized_data = Zlib::GzipReader.open(filename) do |gz|
      JSON.parse(gz.read)
    end

    puts 'Deserializované údaje boli zapísané do súboru.'
    puts deserialized_data["results"].size

    deserialized_data["results"].each do |result|
      #Legal Entity
      legal_entity = LegalEntity.find_or_initialize_by(ico: result["identifiers"].try(:[], 0).try(:[], "value"))
      #ak neexistuje legal_entity s validnymi udajmi tak ho preskoc
      next unless legal_entity

      attributes = {
        first_name: result["statutoryBodies"].try(:first).try(:[], "personName").try(:[], "givenNames")&.join(" "),
        last_name: result["statutoryBodies"].try(:first).try(:[], "personName").try(:[], "familyNames")&.join(" "),
        valid_from: result["identifiers"].try(:first).try(:[], "validFrom")&.to_date,
        entity_name: result["fullNames"].try(:first).try(:[], "value")
      }

      legal_entity.assign_attributes(attributes)
      puts attributes unless legal_entity.valid?
      legal_entity.save if legal_entity.changed?

      raise "Legal Entity not saved: #{legal_entity.inspect}" unless legal_entity.persisted?

      next unless result["addresses"]

      result["addresses"].each do |adress|
        # krajinu vytvorime iba ak este neexistuje v tabulke, na zaklade kodu, find_or_create_by = zabranenie duplicite
        country = Country.find_by(code: adress.try(:[], "country").try(:[], "code"))

        # byebug
        country ||= Country.create!({code: adress.try(:[], "country").try(:[], "code"),
                                   codelist_code: adress.try(:[], "country").try(:[], "codelistCode"),
                                   name: adress.try(:[], "country").try(:[], "value")}
        )


        # unless country.present? && country.valid?
        unless country.persisted? && country.valid?
          puts "Neplatná krajina: #{country.inspect}"
          next
        end

        # Municipality
        municipality = Municipality.find_by(code: adress.try(:[], "municipality").try(:[], "code"))

        # zjavne moze mat municipality iba name cize polickko value
        municipality ||= Municipality.create!({code: adress.try(:[], "municipality").try(:[], "code"),
                                              codelist_code: adress.try(:[], "municipality").try(:[], "codelistCode"),
                                              name: adress.try(:[], "municipality").try(:[], "value")}
        )

        puts "Neplatná obec: #{municipality.errors.full_messages}" unless municipality.valid?


        # byebug
        #
        address = Address.create!({ street: adress.try(:[], "street"),
                         reg_number: adress.try(:[], "regNumber"),
                         building_number: adress.try(:[], "buildingNumber"),
                         postal_code: adress.try(:[], "postalCodes").try(:first),
                         country_id: country&.id,
                         municipality_id: municipality&.id,
                         legal_entity_id: legal_entity.id
                       }
        )

        puts "Neplatná adresa: #{address.errors.full_messages}" unless address.valid?
      end
    end
  end
end