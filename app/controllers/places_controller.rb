# frozen_string_literal: true

class PlacesController < ApplicationController
  before_action :set_place, only: %i[show]

  # GET /places
  # GET /places.json
  def index
    @places = Place
              .all
              .includes(:words)
              .order(:name)
              .paginate(page: params[:page], per_page: 50)
              .load

    # Set @map_places to a hash with data for the map with all places
    @map_places = map_places
  end

  def search
    term = params[:term] || nil
    @places = Place.where('name ILIKE ?', "%#{term}%").order(:name) if term
    respond_to do |format|
      format.json { render 'places/index.json' }
    end
  end

  def id_search
    ids = params[:ids]
    @places = Place.where(id: ids)
    respond_to do |format|
      format.json { render 'places/index.json' }
    end
  end

  # Get a random place and go to its show page
  def random
    redirect_to_random(Place)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_place
    @place = Place.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def place_params
    params.fetch(:place, {})
  end

  def map_places
    # Get all places, filter fields
    temp_map_places = Place.all.select(:latitude, :longitude, :name, :id)

    # New arr. to store data for the map, derived from above db query
    map_places = []

    # Loop through each db record
    temp_map_places.each do |place|
      # Get hash of place data
      hash = place.attributes

      # Add link to hash
      hash['link'] = url_for place

      # Put hash in var
      map_places << hash
    end

    # Return the array of hashes
    map_places
  end
end
