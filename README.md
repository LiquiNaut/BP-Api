# README

This repository contains the backend component of the bachelor's project. It features an API implemented in Ruby using the Rails framework. The project utilizes a local PostgreSQL database for data storage and Redis for managing the execution of cron jobs. The API is specifically designed for handling data from the RPO (Register of Legal Persons and Companies). The data provided by this API is displayed through the frontend component of the project [Rails-main-project](https://github.com/LiquiNaut/Rails-main-project).

Additionally, we have used several gems to enhance the functionality, including:
- **Sidekiq** for background job processing
- **Sidekiq-Cron** for scheduling recurring jobs
- **Nokogiri** for parsing and manipulating HTML and XML
- **ActiveRecord-Import** for efficient bulk data imports
- **Rubyzip** for handling ZIP file operations
