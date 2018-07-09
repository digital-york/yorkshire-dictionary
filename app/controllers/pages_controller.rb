class PagesController < ApplicationController
  def contact
    render 'single_pages/contact'
  end

  def home
    render 'single_pages/home', layout: false
  end

  def about
    render 'single_pages/about'
  end

end