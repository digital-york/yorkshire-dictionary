Rails.application.routes.draw do

  resources :places
  devise_for :users
  root 'pages#home'
  get 'words/search', to: 'words#search'
  get 'words/random', to: 'words#random'
  resources :words, param: :text
  get 'contact', to: 'pages#contact'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
