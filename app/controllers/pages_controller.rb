# frozen_string_literal: true

class PagesController < ApplicationController
  def contact
    @no_help = true
    render 'single_pages/contact'
  end

  def home
    @no_help = true
    render 'single_pages/home', layout: false
  end

  def about
    @no_help = true
    render 'single_pages/about'
  end

  def help
    @no_help = true
    render 'single_pages/help'
  end
end
