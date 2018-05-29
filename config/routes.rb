Rails.application.routes.draw do

  devise_for :users
  
  root 'pages#home'
  
  resources :words, param: :text do
    get 'search', on: :collection
    get 'random', on: :collection
  end
  
  resources :places do
    get 'search', on: :collection
    get 'id_search', on: :collection
  end
  
  
  get 'contact', to: 'pages#contact'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
