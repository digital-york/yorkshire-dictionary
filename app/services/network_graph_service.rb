# frozen_string_literal: true

class NetworkGraphService
  MAX_RELATED_OBJECTS = 15

  def initialize
    # Two inst. vars. to keep track of current node/edge ID
    @node_id = 0
    @edge_id = 0

    # Create two maps to map between the original object (e.g. a Word), and the
    # node representing it in the graph (in both directions)
    @object_nodes = {}
    @node_objects = {}
  end

  def graph(object, depth = 2)
    # Instantiate arrays of nodes and edges which will form graph
    nodes = []
    edges = []

    # Array to keep track of objects which we've already analysed
    branched_objects = []

    # Keep track of how 'deep' we've traversed
    current_depth = 0

    # Create the central node, i.e. the current obj, use larger font
    object_node = node(object, 0, true)
    object_node[:font] = { size: '40' }
    nodes << object_node

    # Add node to two maps of node->object and vise versa
    @object_nodes[object] = object_node
    @node_objects[object_node] = object

    # Add the node to the list of objects which we will branch out from
    to_branch = [object]

    # Iterate until we've gone deep enough
    while current_depth < depth
      # Set of objects to branch from in the next iteration (start empty)
      next_iter_to_branch = Set.new

      # If we still have objects to branch out from...
      while to_branch.any?
        # Get an obj which needs branching
        current = to_branch.pop

        # Skip if we've already done it previously
        next if branched_objects.include? current

        # Get related objs for current obj
        related_objs = all_related_objects current

        # Create nodes for each related obj.
        # TODO: are we skipping links between already branched and current by doing subsequent subtract?
        branched = nodes(current, related_objs - branched_objects)

        # Add related objects to the list of objects which should be branched in
        # next iter
        next_iter_to_branch.merge related_objs

        # Add nodes and edges to overall colleciton
        nodes += branched[:nodes]
        edges += branched[:edges]

        # Record the fact that we've branched the current object
        branched_objects << current
      end

      # Add to_branch from this iter to collection of to_branch, inc. depth
      to_branch += next_iter_to_branch.to_a
      current_depth += 1
    end

    # Add current node to list of nodes
    { nodes: nodes, edges: edges }
  end

  # Get all the related objects for a specific obj
  def all_related_objects(obj)
    related = []

    if obj.respond_to?(:source_materials) && obj&.source_materials&.any?
      related += obj&.source_materials
    end

    related += obj&.places if obj.respond_to?(:places) && obj&.places&.any?

    if obj.respond_to?(:definitions) && obj&.definitions&.any?
      related += obj&.definitions
    end

    if obj.respond_to?(:related_definitions) && obj&.related_definitions&.any?
      related += obj&.related_definitions
    end

    related.take(MAX_RELATED_OBJECTS)
  end

  # Create nodes (with connecting edges) for an object and its related objects
  def nodes(object, related_objects)
    empty_result = { nodes: [], edges: [] }
    return empty_result if related_objects.nil?

    # Get the node for the object
    object_node = @object_nodes[object]
    return empty_result unless object_node

    nodes = []
    edges = []

    related_objects.each do |element|
      # Get the node for the current related obj
      related_node = @object_nodes[element]

      # Create new node if necessary
      unless related_node
        @node_id += 1
        related_node = node(element, @node_id, false)

        # Add mappings between the current related obj. and its node (bidirectional)
        @object_nodes[element] = related_node
        @node_objects[related_node] = element

        nodes << related_node
      end

      # Create edge between original node and the current related obj. node
      @edge_id += 1
      edge = {
        id: @edge_id,
        from: object_node[:id],
        to: related_node[:id]
      }

      edges << edge
    end

    # Return obj with nodes & edges
    { nodes: nodes, edges: edges }
  end

  # Method to call specific node method depending on object type
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

  # Method to create a basic node, which specific nodes derive from
  def generic_node(id, bold, type, url, label)
    truncated_label = if label
                  label.truncate 15
                else
                  'No name'
                end

    label_text = if bold
                   "<b>#{truncated_label}</b>"
                 else
                   truncated_label
                 end
    {
      id: id, type: type,
      url: url, label: label_text
    }
  end

  # Node for a place
  def place_node(place, node_id, bold = false)
    node = generic_node(
      node_id, bold, 'place',
      Rails.application.routes.url_helpers.place_path(place),
      place.name
    )
    node[:color] = '#41aff4'
    node
  end

  # Node for a source material
  def source_node(source, node_id, bold = false)
    node = generic_node(
      node_id, bold, 'source',
      Rails.application.routes.url_helpers.source_material_path(source),
      source.title
    )
    node[:color] = '#e8d335'
    node
  end

  # Node for a definition
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
