# frozen_string_literal: true

require 'sidekiq'

Sidekiq.configure_server do |config|
  config.options[:max_retries] = 0
  config.options[:timeout] = 60
end