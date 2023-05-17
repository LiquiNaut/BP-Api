# frozen_string_literal: true

class RpoBatchDailyJob < ApplicationJob
  queue_as :default
  require 'open-uri'
  require 'rubygems/package'
  require 'json'
  require 'zlib'
  require 'fileutils'
  require 'date'

  def perform(*args)
    # DAILY BATHCES
    #

    today = Date.today

    # vytvorenie .txt logovacieho suboru
    log_filename = 'Job_log.txt'
    FileUtils.touch(log_filename) unless File.exist?(log_filename)

    File.open(log_filename, 'a') do |logfile|
      logfile.puts "DOWNLOADING DAILY BATCH: #{today} - TIME: #{Time.now.strftime('%H:%M:%S')}"
      logfile.flush

      directory_name = "batch-daily"

      # Vytvorenie priečinka, ak neexistuje
      FileUtils.mkdir_p(directory_name)

      formatted_date = today.strftime('%Y-%m-%d')
      url = "https://frkqbrydxwdp.compat.objectstorage.eu-frankfurt-1.oraclecloud.com/susr-rpo/batch-daily/actual_#{formatted_date}.json.gz"

      compressed_file = "#{directory_name}/actual_#{formatted_date}.json.gz"
      output_file = "#{directory_name}/actual_#{formatted_date}.json"

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

      # PARSER
      #
      # filename = Rails.root.join('batch-init', '2023-04-01_001.json.gz')
      filename = Rails.root.join('batch-daily', "actual_#{formatted_date}.json.gz")
      # Otvorí a deserializuje súbor
      deserialized_data = Zlib::GzipReader.open(filename) do |gz|
        JSON.parse(gz.read)
      end

      logfile.puts "PARSING DAILY BATCH: #{today} - TIME: #{Time.now.strftime('%H:%M:%S')}"
      logfile.flush

      # Prepare data for bulk insertion
      legal_entities_data = []
      addresses_data = []

      deserialized_data["results"].each do |result|
        ico = result["identifiers"]&.dig(0, "value")
        next unless ico

        legal_entity = {
          ico: ico,
          first_name: result.dig("statutoryBodies", 0, "personName", "givenNames")&.join(" "),
          last_name: result.dig("statutoryBodies", 0, "personName", "familyNames")&.join(" "),
          entity_name: result.dig("fullNames", 0, "value")
        }

        legal_entities_data << legal_entity

        next unless result["addresses"]

        result["addresses"].each do |address_data|
          country_code = address_data.dig("country", "code")
          country = Country.find_or_create_by(code: country_code) do |c|
            c.codelist_code = address_data.dig("country", "codelistCode")
            c.name = address_data.dig("country", "value")
          end

          municipality_code = address_data.dig("municipality", "code")
          municipality = Municipality.find_or_create_by(code: municipality_code) do |m|
            m.codelist_code = address_data.dig("municipality", "codelistCode")
            m.name = address_data.dig("municipality", "value")
          end

          address = {
            postal_code: address_data.dig("postalCodes", 0),
            street: address_data.dig("street"),
            reg_number: address_data.dig("regNumber"),
            building_number: address_data.dig("buildingNumber"),
            country_id: country.id,
            municipality_id: municipality.id,
            legal_entity_id: ico
          }

          addresses_data << address
        end
      end

      # Bulk insert legal_entities_data
      imported_legal_entities = LegalEntity.import legal_entities_data, validate: true, on_duplicate_key_update: [:first_name, :last_name, :entity_name], returning: [:id, :ico]

      # Map ICOs to LegalEntity IDs
      ico_to_legal_entity_id = imported_legal_entities.results.map { |result| [result[1], result[0]] }.to_h

      # Update legal_entity_id in addresses_data
      addresses_data.each do |address_data|
        address_data[:legal_entity_id] = ico_to_legal_entity_id[address_data[:legal_entity_id]]
      end

      # Bulk insert addresses_data
      Address.import addresses_data, validate: true, on_duplicate_key_update: [:postal_code, :street, :reg_number, :building_number, :country_id, :municipality_id, :legal_entity_id]
    end
  end
end
