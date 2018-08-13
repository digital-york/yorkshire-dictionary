# frozen_string_literal: true

# Controller for Word class
class WordsController < ApplicationController
  # Define the actions to complete before various controller actions
  before_action :set_word, only: %i[show update]
  before_action :set_sort_options, only: %i[index search]

  # GET /words
  # GET /words.json
  def index
    # Uses will_paginate gem
    @words = Word
             .includes(
               definitions: [
                 { related_definitions: :word },
                 :places,
                 :alt_spellings,
                 :source_materials,
                 :source_dates
               ]
             )
             .order(sort_order)
             .paginate(page: params[:page], per_page: 50)
             .load
  end

  # Get a random word and go to its show page
  def random
    # Get random num between 0 and num words
    offset = rand(Word.count)

    # Get word record at random offset
    @word = Word.offset(offset).first

    redirect_to @word
  end

  # GET /words/1
  # GET /words/1.json
  def show; end

  def search
    # Uses will_paginate gem
    @words =  Word
              .search(
                text: params[:search],
                places: params[:place],
                letter: params[:letter],
                start_year: params[:start_year],
                end_year: params[:end_year],
                source_material_ids: params[:source],
                def_text: params[:definition_text],
                any: params[:any]
              )
              .order(sort_order)
              .paginate(page: params[:page], per_page: 50)
    render 'index'
  end

  def homepage
    @words = Word.all
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_word
    @word = Word.find_by_text(params[:text])
  end

  # Set @sort_orders to be a map of sort option text -> string representing field_sortorder (used by sort_order)
  def set_sort_options
    @sort_orders = {
      'Word (A-Z)' => 'text_asc',
      'Word (Z-A)' => 'text_desc',
      # 'Place (A-Z)' => 'word.places_asc',
      # 'Place (Z-A)' => 'word.places_desc',
      # 'Source name (A-Z)' => 'source_asc',
      # 'Source name (Z-A)' => 'source_desc',
      # 'Date (most recent)' => 'date_desc',
      # 'Date (oldest)' => 'date_asc',
    }
  end

  # Retrieve the 'sort' param, and split it to get the sort field and direction
  def sort_order
    sort_string = params[:sort]
    if sort_string
      split = sort_string.split '_'
      sort_field = split[0]
      sort_dir = split[1]
      return {sort_field.to_sym => sort_dir}
    end
    return {text: :asc}
  end

  # Set @all_sources to be a map of truncate(original_ref) -> id, used by the sources select list of the search view
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

  # Set @all_places to be used by the select list in the search view
  def set_places
    @all_places = Place.all.select('name,id').order :name
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def word_params
    params.require(:word).permit(:word)
  end
end
