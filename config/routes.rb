# frozen_string_literal: true

Rails.application.routes.draw do
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)

  root 'pages#home'

  resources :words, param: :text do
    get 'search', on: :collection
    get 'random', on: :collection
  end

  resources :network_graphs

  resources :places do
    get 'search', on: :collection
    get 'id_search', on: :collection
  end

  resources :source_materials do
    get 'search', on: :collection
    get 'id_search', on: :collection
  end

  get 'contact', to: 'pages#contact'
  get 'about', to: 'pages#about'

  resources :submissions

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
