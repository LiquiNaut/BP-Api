Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"
end
