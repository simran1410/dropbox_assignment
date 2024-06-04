Rails.application.routes.draw do
  resources :invites, only: [:new, :create] do
    collection do
      get :get_token
    end
  end
  get '/callback', to: 'invites#callback'

  root 'invites#new'
end
