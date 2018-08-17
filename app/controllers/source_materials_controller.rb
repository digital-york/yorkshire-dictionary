# frozen_string_literal: true

class SourceMaterialsController < ApplicationController
  before_action :set_source_material, only: %i[show]

  # GET /source_materials
  # GET /source_materials.json
  def index
    @source_materials = SourceMaterial
                        .all
                        .order(:title)
                        .paginate(page: params[:page], per_page: 50)
  end

  # GET /source_materials/1
  # GET /source_materials/1.json
  def show; end

  def search
    term = params[:term] || nil
    @source_materials = SourceMaterial.where('title ILIKE ?', "%#{term}%").order(:title) if term
    respond_to do |format|
      format.json { render 'source_materials/index.json' }
    end
  end

  def id_search
    ids = params[:ids]
    @source_materials = SourceMaterial.where(id: ids)
    respond_to do |format|
      format.json { render 'source_materials/index.json' }
    end
  end

  # Get a random source material obj and go to its show page
  def random
    redirect_to_random(SourceMaterial)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_source_material
    @source_material = SourceMaterial
                       .includes(
                         source_references:
                          %i[source_excerpts definition word]
                        )
                       .find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def source_material_params
    params.fetch(:source_material, {})
  end
end
