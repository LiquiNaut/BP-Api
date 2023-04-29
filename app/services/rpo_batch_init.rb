class RpoBatchInit

  require 'open-uri'
  require 'rubygems/package'
  require 'json'
  require 'zlib'
  require 'fileutils'
  require 'date'

  # require 'byebug'

  def self.perform

    puts "START"

    buffer_size = 1024 * 1024 # Veľkosť buffera nastavená na 1 MB
    directory_name = "batch-init"

    # Vytvorenie priečinka, ak neexistuje
    FileUtils.mkdir_p(directory_name)

    # Zisti datum prvej soboty mesiaca
    def self.first_saturday_of_month(year, month)
      date = Date.new(year, month, 1)
      date += (6 - date.wday) % 7
      date.strftime('%Y-%m-%d')
    end

    today = Date.today
    first_saturday = first_saturday_of_month(today.year, today.month)

    # vytvorenie .txt logovacieho suboru
    log_filename = 'log.txt'
    FileUtils.touch(log_filename) unless File.exist?(log_filename)

    File.open(log_filename, 'a') do |logfile|

      # BATCH INIT - DOWNLOAD
      #
      # (1..21).each do |i|
      #   logfile.puts "DOWNLOADING BATCH INIT #{i} - TIME: #{Time.now.strftime('%H:%M:%S')}"
      #   logfile.flush
      #
      #   file_number = format('%03d', i) # Formátuj číslo súboru na 3 číslice s nulami
      #   url = "https://frkqbrydxwdp.compat.objectstorage.eu-frankfurt-1.oraclecloud.com/susr-rpo/batch-init/init_#{first_saturday}_#{file_number}.json.gz"
      #
      #   compressed_file = "#{directory_name}/#{first_saturday}_#{file_number}.json.gz"
      #   output_file = "#{directory_name}/#{first_saturday}_#{file_number}.json"
      #
      #   # Stiahnutie súboru
      #   File.open(compressed_file, 'wb') do |local_file|
      #     URI.open(url, 'rb', :content_length_proc => lambda { |content_length| }) do |remote_file|
      #       while (buffer = remote_file.read(buffer_size))
      #         local_file.write(buffer)
      #       end
      #     end
      #   end
      #
      #   # Dekompresia súboru
      #   Zlib::GzipReader.open(compressed_file) do |gz|
      #     File.open(output_file, 'wb') do |file|
      #       file.write(gz.read)
      #     end
      #   end
      #
      #   # Zmazanie komprimovaných suborov
      #   # File.delete(compressed_file)
      #
      #   logfile.puts "Súbor č. #{file_number} bol úspešne stiahnutý, dekompresovaný a uložený ako #{output_file} - TIME: #{Time.now.strftime('%H:%M:%S')}"
      #   logfile.flush
      # end

      # BATCH INIT - PARSER
      #
      (1..21).each do |fileNum|
        logfile.puts "PARSING BATCH INIT #{fileNum} - TIME: #{Time.now.strftime('%H:%M:%S')}"
        logfile.flush

        fileNum = format('%03d', fileNum)
        # filename = Rails.root.join('batch-init', '2023-04-01_001.json.gz')
        filename = Rails.root.join('batch-init', "#{first_saturday}_#{fileNum}.json.gz")
        # Otvorí a deserializuje súbor
        deserialized_data = Zlib::GzipReader.open(filename) do |gz|
          JSON.parse(gz.read)
        end

        puts deserialized_data["results"].size

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
            valid_from: result.dig("identifiers", 0, "validFrom")&.to_date,
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
        imported_legal_entities = LegalEntity.import legal_entities_data, validate: true, on_duplicate_key_update: [:first_name, :last_name, :valid_from, :entity_name], returning: [:id, :ico]

        # Map ICOs to LegalEntity IDs
        ico_to_legal_entity_id = imported_legal_entities.results.map { |result| [result[1], result[0]] }.to_h

        # Update legal_entity_id in addresses_data
        addresses_data.each do |address_data|
          address_data[:legal_entity_id] = ico_to_legal_entity_id[address_data[:legal_entity_id]]
        end

        # Bulk insert addresses_data
        Address.import addresses_data, validate: true

      end

      # DAILY BATHCES
      #
      # dotiahnutie zvysku daily batchov po aktualny den
      def self.first_saturday_of_month_date(year, month)
        date = Date.new(year, month, 1)
        date += (6 - date.wday) % 7
        date
      end

      today = Date.today
      first_saturday = first_saturday_of_month_date(today.year, today.month)

      # num_days = (today - first_saturday).numerator
      # (0..num_days).reverse_each do |i|
      (first_saturday..today).each do |current_date|
        logfile.puts "DOWNLOADING DAILY BATCH: #{current_date} - TIME: #{Time.now.strftime('%H:%M:%S')}"
        logfile.flush
        # day = today.day - i
        #
        # date = Date.new(today.year, today.month, day)
        # today = date.strftime('%Y-%m-%d')

        directory_name = "batch-daily"

        # Vytvorenie priečinka, ak neexistuje
        FileUtils.mkdir_p(directory_name)

        formatted_date = current_date.strftime('%Y-%m-%d')
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

        logfile.puts "PARSING DAILY BATCH: #{current_date} - TIME: #{Time.now.strftime('%H:%M:%S')}"
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
            valid_from: result.dig("identifiers", 0, "validFrom")&.to_date,
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
        imported_legal_entities = LegalEntity.import legal_entities_data, validate: true, on_duplicate_key_update: [:first_name, :last_name, :valid_from, :entity_name], returning: [:id, :ico]

        # Map ICOs to LegalEntity IDs
        ico_to_legal_entity_id = imported_legal_entities.results.map { |result| [result[1], result[0]] }.to_h

        # Update legal_entity_id in addresses_data
        addresses_data.each do |address_data|
          address_data[:legal_entity_id] = ico_to_legal_entity_id[address_data[:legal_entity_id]]
        end

        # Bulk insert addresses_data
        Address.import addresses_data, validate: true

      end
      # end
      logfile.puts "DONE - TIME: #{Time.now.strftime('%H:%M:%S')}"
      logfile.close
    end
  end
end
