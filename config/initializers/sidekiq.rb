# frozen_string_literal: true
require 'sidekiq'
require 'sidekiq-cron'

Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://localhost:6379/0' }
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://localhost:6379/0' }
end

# nastavenie casu pre sidekiq CRON JOB, dobre by to bolo nastavit na cca 4:00 am kazdy den lebo batche vychadzaju o 3:00 am
job = Sidekiq::Cron::Job.new(name: 'Rpo Batch Daily Job - every day at 7:00', cron: '00 7 * * *', class: 'RpoBatchDailyJob')
unless job.save
  Rails.logger.error "Failed to save Sidekiq job: #{job.errors.full_messages.join(', ')}"
end
