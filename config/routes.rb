Rails.application.routes.draw do

  devise_for :users
  root 'pages#home'
  get 'words/search', to: 'words#search'
  resources :words, param: :text
  get 'contact', to: 'pages#contact'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
