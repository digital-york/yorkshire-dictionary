# frozen_string_literal: true

class PlacesController < ApplicationController
  before_action :set_place, only: %i[show edit update destroy]

  # GET /places
  # GET /places.json
  def index
    @places = Place
              .all
              .includes(:definitions, :words)
              .order(:name)
              .paginate(page: params[:page], per_page: 50)

    # Set @map_places to a hash with data for the map with all places
    @map_places = map_places
  end

  # GET /places/1
  # GET /places/1.json
  def show; end

  # GET /places/new
  def new
    @place = Place.new
  end

  # GET /places/1/edit
  def edit; end

  # POST /places
  # POST /places.json
  def create
    @place = Place.new(place_params)

    respond_to do |format|
      if @place.save
        format.html { redirect_to @place, notice: 'Place was successfully created.' }
        format.json { render :show, status: :created, location: @place }
      else
        format.html { render :new }
        format.json { render json: @place.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /places/1
  # PATCH/PUT /places/1.json
  def update
    respond_to do |format|
      if @place.update(place_params)
        format.html { redirect_to @place, notice: 'Place was successfully updated.' }
        format.json { render :show, status: :ok, location: @place }
      else
        format.html { render :edit }
        format.json { render json: @place.errors, status: :unprocessable_entity }
      end
    end
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

  # DELETE /places/1
  # DELETE /places/1.json
  def destroy
    @place.destroy
    respond_to do |format|
      format.html { redirect_to places_url, notice: 'Place was successfully destroyed.' }
      format.json { head :no_content }
    end
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
