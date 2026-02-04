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
      member do
        post :reset_password
      end
    end
    resources :themes
    resources :trainings do
      collection do
        get :import
        post :process_import
        get :export
      end
      member do
        post :toggle_publish
      end
    end
    resources :quizzes do
      resources :questions do
        collection do
          get :import
          post :process_import
          get :export
          get :download_template
          delete :destroy_all
        end
      end
      member do
        post :create_quiz_session
      end
    end
    resources :activity_reports, only: [:index] do
      collection do
        get :export
      end
      member do
        get :user_report
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

    get "DAOE/:pdf_name", to: "exercices#daoe", as: :daoe_pdf

    resources :activity_reports, only: [:index] do
      member do
        get :user_report
      end
    end
  end

  get "q/:token", to: "quiz_sessions#show", as: :quiz_session
  post "q/:token/participants", to: "quiz_sessions#create_participant", as: :quiz_session_participants
  post "q/:token/answer", to: "quiz_sessions#submit_answer", as: :quiz_session_submit_answer

  namespace :bureau do
    get "dashboard", to: "dashboard#index"
    resources :projects do
      resources :tasks, only: [:new, :create]
      member do
        get :gantt
        get :list
        get :todo
        get :gantt_data
        get :gantt_users
      end
    end
    resources :tasks, only: [:index, :show, :edit, :update, :destroy] do
      collection do
        get :calendar
        get :todo
      end
    end

    resources :task_dependencies, only: [:create, :destroy]
  end
  resources :trainings, only: [:index, :show] do
    collection do
      get :catalog_pdf
    end
    member do
      get :show_catalog
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
