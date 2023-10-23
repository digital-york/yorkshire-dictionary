# frozen_string_literal: true

class NetworkGraphsController < ApplicationController
  def show
    definition_id = params[:id]

    definition = Definition.find(definition_id)

    graph_data = NetworkGraphService.new.graph(definition)

    render json: graph_data
  end

end
