Rails.application.routes.draw do
  # Health checks
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "health#check", as: :health_check

  # Home page
  root "pages#home"

  # Pages
  get "home", to: "pages#home"

  # Authentication routes
  get '/login', to: 'sessions#new', as: 'login'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy', as: 'logout'
  get '/register', to: 'users#new', as: 'register'
  post '/register', to: 'users#create'
  
  # User profile
  get '/profile', to: 'users#show', as: 'profile'

  resources :pdf_documents do
    member do
      post :generate
      get :preview
      post :duplicate
    end
  end

  resources :pdf_templates do
    member do
      post :use
    end
  end

  resources :pdf_snippets

  # PDF Editor routes
  namespace :pdf_editor do
    resources :documents, only: [] do
      resources :elements do
        member do
          patch :move
          patch :resize
          patch :update_properties
        end
      end
    end
  end


  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
