(function wrap() {
  /* globals vis */

  let nodeData = [];

  // Get the canvas HTML element
  function getNetworkContainers() {
    return document.querySelectorAll(".network-graph-container");
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

  function changeCursor(container, style) {
    container.getElementsByTagName('canvas')[0].style.cursor = style;
  }

  function createGraph(container, nodes, edges) {
    const options = { interaction: { hover: true, hoverConnectedEdges: false }, nodes: { font: { size: 20, multi: true, face: "Heebo" } }, edges: { chosen: false, color: { color: "black", inherit: false, opacity: 0.4 }, width: 2 } };

    const data = { nodes, edges };

    const definitionId = container.dataset.definitionId;
    const graphDiv = container.querySelector('.network-graph');

    // Save node data since it's used to lookup data for a node when clicked
    nodes.forEach(node => {
      nodeData[node.id] = node;
    });

    // initialize your network!
    const network = new vis.Network(graphDiv, data, options);

    network.on("hoverNode", () => {
      changeCursor(graphDiv, "pointer");
    });

    network.on("blurNode", () => {
      changeCursor(graphDiv, "default");
    });

    network.on("click", nodeClick);

    network.on("stabilized", () => {
      $(graphDiv).show();
      $(`.network-graph-container[data-definition-id="${definitionId}"] .network-graph-loading-message`).hide();
      network.fit();

    });

    return network;
  }

  function setUpNetworkGraphs() {
    const containers = getNetworkContainers();
    if (!containers.length) {
      return;
    }
    
    containers.forEach((container) => {
      const definitionId = container.dataset.definitionId;
  
      const dataUrl = Routes.network_graph_path({ id: definitionId });
  
      $.getJSON({
        url: dataUrl,
        type: 'get',
        data: {
          id: definitionId,
        },
      }).done(
        (data) => {
          createGraph(container, data.nodes, data.edges);
        },
      );
    });

  }

  $(document).on('turbolinks:load', setUpNetworkGraphs);
}());
