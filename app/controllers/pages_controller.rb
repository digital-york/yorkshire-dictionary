class PagesController < ApplicationController

  def contact
    render 'contact/contact'
  end
  
  def home
    render 'single_pages/home'
  end

end