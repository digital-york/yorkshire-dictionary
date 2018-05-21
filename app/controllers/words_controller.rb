# frozen_string_literal: true

class WordsController < ApplicationController
  before_action :set_word, only: %i[show edit update destroy]
  before_action :set_places, only: %i[index search]
  before_action :set_sources, only: %i[index search]
  before_action :authenticate_user!, except: %i[index search show random]
  before_action :authenticate_admin, except: %i[index search show random]

  # GET /words
  # GET /words.json
  def index
    # Uses will_paginate gem
    @words = Word
      .paginate(page: params[:page], per_page: 50)
  end

  def random
    offset = rand(Word.count)
    @word = Word.offset(offset).first

    redirect_to @word
  end
  
  # GET /words/1
  # GET /words/1.json
  def show
    @word = Word.find_by_text(params[:text])
    get_word_data(@word)
  end

  # GET /words/new
  def new
    @word = Word.new
  end

  def search
    # Uses will_paginate gem
    @words = Word
             .search(
               text: params[:search],
               places: params[:search_places],
               letter: params[:letter],
               source_material_refs: params[:search_source_materials],
               def_text: params[:search_definition_text],
               any: params[:any]
             )
             .paginate(page: params[:page], per_page: 50)
    render 'index'
  end

  # GET /words/1/edit
  def edit; end

  def homepage
    @words = Word.all
  end

  # POST /words
  # POST /words.json
  def create
    @word = Word.new(word_params)

    respond_to do |format|
      if @word.save
        format.html { redirect_to @word, notice: 'Word was successfully created.' }
        format.json { render :show, status: :created, location: @word }
      else
        format.html { render :new }
        format.json { render json: @word.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /words/1
  # PATCH/PUT /words/1.json
  def update
    respond_to do |format|
      if @word.update(word_params)
        format.html { redirect_to @word, notice: 'Word was successfully updated.' }
        format.json { render :show, status: :ok, location: @word }
      else
        format.html { render :edit }
        format.json { render json: @word.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /words/1
  # DELETE /words/1.json
  def destroy
    @word.destroy
    respond_to do |format|
      format.html { redirect_to words_url, notice: 'Word was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_word
      @word = Word.find_by_text(params[:text])
    end
    
    def set_places
      @all_places = Place.all.select('name,id').order :name
    end

    def set_sources
      truncate_len = 30
      @all_sources = {}
      sources = SourceMaterial.all.select('original_ref,id,ref').order :original_ref
      sources.each do |x|
        truncated_ref = if x&.original_ref
                          x.original_ref.truncate(truncate_len)
                        elsif x&.ref
                          x.ref.truncate(truncate_len)
                        else
                          'No reference'
                        end
        @all_sources[truncated_ref] = x.id
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def word_params
      params.require(:word).permit(:word)
    end

    def authenticate_admin
      flash[:error] = "You're not authenticated to access that page."
      redirect_to root_path unless current_user.admin? 
    end

    def get_word_data(word)
      @defs = word.definitions
    end
end
