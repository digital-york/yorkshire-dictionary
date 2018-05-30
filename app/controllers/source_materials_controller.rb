class SourceMaterialsController < ApplicationController
  before_action :set_source_material, only: [:show, :edit, :update, :destroy]

  # GET /source_materials
  # GET /source_materials.json
  def index
    @source_materials = SourceMaterial.all
  end

  # GET /source_materials/1
  # GET /source_materials/1.json
  def show
  end

  # GET /source_materials/new
  def new
    @source_material = SourceMaterial.new
  end

  # GET /source_materials/1/edit
  def edit
  end

  # POST /source_materials
  # POST /source_materials.json
  def create
    @source_material = SourceMaterial.new(source_material_params)

    respond_to do |format|
      if @source_material.save
        format.html { redirect_to @source_material, notice: 'Source material was successfully created.' }
        format.json { render :show, status: :created, location: @source_material }
      else
        format.html { render :new }
        format.json { render json: @source_material.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /source_materials/1
  # PATCH/PUT /source_materials/1.json
  def update
    respond_to do |format|
      if @source_material.update(source_material_params)
        format.html { redirect_to @source_material, notice: 'Source material was successfully updated.' }
        format.json { render :show, status: :ok, location: @source_material }
      else
        format.html { render :edit }
        format.json { render json: @source_material.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /source_materials/1
  # DELETE /source_materials/1.json
  def destroy
    @source_material.destroy
    respond_to do |format|
      format.html { redirect_to source_materials_url, notice: 'Source material was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def search
    term = params[:term] || nil
    sources = SourceMaterial.where('original_ref ILIKE ?', "%#{term}%").order(:original_ref) if term
    render json: sources
  end

  def id_search
    ids = params[:ids]
    sources = SourceMaterial.where(id: ids)
    render json: sources
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_source_material
      @source_material = SourceMaterial.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def source_material_params
      params.fetch(:source_material, {})
    end
end