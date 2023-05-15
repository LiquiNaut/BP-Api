Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  require "sidekiq/web"
  require 'sidekiq/cron/web'
  mount Sidekiq::Web => "/sidekiq"

  namespace :api, defaults: { format: :json }, constraints: { format: 'json' } do
    get :search, to: 'search#search'
    get :tax_rep, to: 'search#tax_rep'
    get :search_by_name, to: 'search#search_by_name'
  end
end
