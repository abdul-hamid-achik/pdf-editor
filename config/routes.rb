Rails.application.routes.draw do
  # Health checks
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "health#check", as: :health_check

  # PDF Editor routes
  root "pdf_documents#index"
  
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

  # Authentication routes (placeholder - will be implemented later)
  # get '/login', to: 'sessions#new'
  # post '/login', to: 'sessions#create'
  # delete '/logout', to: 'sessions#destroy'
  # get '/register', to: 'users#new'
  # post '/register', to: 'users#create'

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
