class ApplicationController < ActionController::Base
  # Get a random word and go to its show page
  def redirect_to_random(clazz)
    # Get random num between 0 and num words
    offset = rand(clazz.count)

    # Get word record at random offset
    @obj = clazz.offset(offset).first

    redirect_to @obj
  end
end
