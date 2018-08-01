(function wrap() {
  /* globals vis */

  let nodeData = [];

  // Get the canvas HTML element
  function getNetworkCanvas() {
    return document.getElementById('network-graph').getElementsByTagName('canvas')[0];
  }

  function nodeClick(params) {
    if (params.nodes.length) {
      const selectedNode = params.nodes[0];
      const data = nodeData[selectedNode];
      if (Turbolinks) {
        Turbolinks.visit(data.url);
      } else {
        window.location = data.url;
      }
    }
  }

  function changeCursor(style) {
    getNetworkCanvas().style.cursor = style;
  }

  function createGraph(nodes, edges) {
    // create a network
    const container = document.getElementById('network-graph');

    const options = {
      interaction: { hover: true, hoverConnectedEdges: false },
      nodes: {
        font: {
          size: 20,
          multi: true,
          face: 'Heebo'
        },
      },
      edges: {
        chosen: false,
        color: {
          color: 'black',
          inherit: false,
          opacity: 0.4,
        },
        width: 2,
      },
    };

    const data = { nodes, edges };

    // Save node data since it's used to lookup data for a node when clicked
    nodes.forEach((node) => {
      nodeData[node.id] = node;
    });

    // initialize your network!
    const network = new vis.Network(container, data, options);

    network.on('hoverNode', () => {
      changeCursor('pointer');
    });

    network.on('blurNode', () => {
      changeCursor('default');
    });

    network.on('click', nodeClick);

    network.on('stabilized', () => {
      $('#network-graph-container').show();
      $('#network-graph-loading-message').hide();
    });

    return network;
  }

  function setUpNetworkGraph() {
    if (!$('#network-graph').length) {
      return;
    }

    const definitionId = $('#network-graph').data('definition-id');

    const dataUrl = Routes.network_graph_path({ id: definitionId });

    $.getJSON({
      url: dataUrl,
      type: 'get',
      data: {
        id: definitionId,
      },
    }).done(
      (data) => {
        createGraph(data.nodes, data.edges);
      },
    );
  }

  $(document).on('turbolinks:load', setUpNetworkGraph);
}());
