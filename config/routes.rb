Rails.application.routes.draw do
  devise_for :users
  devise_scope :user do
    get '/users/sign_out', to: 'devise/sessions#destroy'
  end
  
  root to: "home#index"
  get "dashboard", to: "home#dashboard"

  namespace :admin do
    get "dashboard", to: "dashboard#index"
    resources :users do
      collection do
        get :import
        post :process_import
        get :download_template
      end
    end
    resources :courses
    resources :themes
    resources :quizzes do
      resources :questions do
        collection do
          get :import
          post :process_import
          get :export
          get :download_template
        end
      end
      member do
        get :assign_users
        post :update_assignments
      end
    end
  end

  namespace :formateur do
    get "dashboard", to: "dashboard#index"
    resources :quizzes, only: [:index, :show] do
      resources :questions, only: [:index, :show]
    end

    get "exercices", to: "exercices#index"

    get "exercices/dragdrop", to: "exercices#dragdrop"

    get "exercices/elingage", to: "exercices#elingage"
  end

  namespace :apprenant do
    get "dashboard", to: "dashboard#index"
    resources :quiz_attempts, only: [:index, :show, :new, :create] do
      member do
        post :submit_answer
        post :complete
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
