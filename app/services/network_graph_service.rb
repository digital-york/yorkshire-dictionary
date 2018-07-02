# frozen_string_literal: true

class NetworkGraphService
  MAX_RELATED_OBJECTS = 15

  def initialize
    @node_id = 0
    @edge_id = 0

    @object_nodes = {}
    @node_objects = {}
  end

  def graph(object, depth = 2)
    nodes = []
    edges = []

    branched_objects = []

    current_depth = 0

    object_node = node(object, 0, true)
    object_node[:font] = { size: '40' }

    @object_nodes[object] = object_node
    @node_objects[object_node] = object

    to_branch = [object]

    while current_depth < depth
      next_iter_to_branch = Set.new
      # FIXME: this next loop isn't finishing
      while to_branch.any?
        current = to_branch.pop
        next if branched_objects.include? current

        related_objs = all_related_objects current

        branched = nodes(current, related_objs - branched_objects)

        # TODO: does this line work? VV
        next_iter_to_branch.merge related_objs

        nodes += branched[:nodes]
        edges += branched[:edges]
        branched_objects << current
      end
      to_branch += next_iter_to_branch.to_a
      current_depth += 1
    end

    nodes << object_node

    { nodes: nodes, edges: edges }
  end

  def all_related_objects(obj)
    related = []

    if obj.respond_to?(:source_materials) && obj&.source_materials.any?
      related += obj&.source_materials
    end

    related += obj&.places if obj.respond_to?(:places) && obj&.places.any?

    if obj.respond_to?(:definitions) && obj&.definitions.any?
      related += obj&.definitions
    end

    if obj.respond_to?(:related_definitions) && obj&.related_definitions.any?
      related += obj&.related_definitions
    end

    related.take(MAX_RELATED_OBJECTS)
  end

  def nodes(object, related_objects)
    empty_result = { nodes: [], edges: [] }

    return empty_result if related_objects.nil?

    object_node = @object_nodes[object]

    return empty_result unless object_node

    nodes = []
    edges = []

    related_objects.each do |element|
      related_node = @object_nodes[element]
      unless related_node
        @node_id += 1
        related_node = node(element, @node_id, false)

        @object_nodes[element] = related_node

        # Add the original model object to hash
        @node_objects[related_node] = element

        nodes << related_node
      end

      @edge_id += 1
      edge = {
        id: @edge_id,
        from: object_node[:id],
        to: related_node[:id]
      }

      edges << edge
    end

    { nodes: nodes, edges: edges }
  end

  def node(object, id, bold = false)
    case object&.class&.name
    when 'Place'
      place_node(object, id, bold)
    when 'SourceMaterial'
      source_node(object, id, bold)
    when 'Definition'
      definition_node(object, id, bold)
    end
  end

  def generic_node(id, bold, type, url, label)
    truncated = label.truncate 15
    label_text = if bold
                   "<b>#{truncated}</b>"
                 else
                   truncated
                  end
    {
      id: id, type: type,
      url: url, label: label_text
    }
  end

  def place_node(place, node_id, bold = false)
    node = generic_node(
      node_id, bold, 'place',
      Rails.application.routes.url_helpers.place_path(place),
      place.name
    )
    node[:color] = '#41aff4'
    node
  end

  def source_node(source, node_id, bold = false)
    node = generic_node(
      node_id, bold, 'source',
      Rails.application.routes.url_helpers.source_material_path(source),
      source.title
    )
    node[:color] = '#e8d335'
    node
  end

  def definition_node(definition, node_id, bold = false)
    node = generic_node(
      node_id, bold, 'definition',
      Rails.application.routes.url_helpers.word_path(definition.word),
      definition.word.text
    )
    node[:color] = '#b9e07f'
    node
  end
end
