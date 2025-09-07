// Graph Visualization with D3.js
let currentStateIndex = 0;
let states = [];
let simulation = null;
let svg = null;
let g = null;
let isPlaying = false;
let playInterval = null;
let eventSource = null;
let autoFollow = false;
let autoGenerate = false;
let currentNodes = [];
let currentEdges = [];
let nodeById = new Map();
let linkGroup = null;
let nodeGroup = null;
let currentZoom = 1;
let useCanvas = false;
let canvas = null;
let context = null;
let hiddenCanvas = null;
let hiddenContext = null;
let nodeColorMap = new Map();
let nextColorIndex = 1;
let hoveredNode = null;

// Color mapping for room labels
const labelColors = {
    'A': '#ff7f7f',
    'B': '#7f7fff',
    'C': '#7fff7f',
    'D': '#ffff7f'
};

// Helper function to parse query path and identify which edges and nodes to highlight
function parseQueryPath(queryPath, edges) {
    if (!queryPath) return { pathEdges: new Set(), pathNodes: new Set() };
    
    const pathEdges = new Set();
    const pathNodes = new Set();
    let currentNode = 'START';
    
    // Add starting node
    pathNodes.add('START');
    
    // For each door in the path
    for (let i = 0; i < queryPath.length; i++) {
        const door = parseInt(queryPath[i]);
        
        // Find the edge from currentNode with this door number
        for (const edge of edges) {
            if (edge.source.id ? edge.source.id === currentNode : edge.source === currentNode) {
                if (edge.door === door) {
                    // Create a unique key for this edge
                    const edgeKey = `${edge.source.id || edge.source}-${edge.target.id || edge.target}-${edge.door}`;
                    pathEdges.add(edgeKey);
                    
                    // Move to the next node
                    currentNode = edge.target.id || edge.target;
                    pathNodes.add(currentNode);
                    break;
                }
            }
        }
    }
    
    return { pathEdges, pathNodes };
}

// Initialize the visualization
document.addEventListener('DOMContentLoaded', function() {
    initializeVisualization();
    loadStates();
    startLiveUpdates();
    
    // Speed slider event
    document.getElementById('speedSlider').addEventListener('input', function(e) {
        document.getElementById('speedValue').textContent = (e.target.value / 1000).toFixed(1) + 's';
    });
});

function initializeVisualization() {
    // Set up SVG to use full window
    const width = window.innerWidth;
    const height = window.innerHeight;
    
    svg = d3.select('#graph-svg')
        .attr('width', width)
        .attr('height', height)
        .style('width', '100%')
        .style('height', '100%');
    
    // Add canvas for high-performance rendering
    canvas = d3.select('#visualization')
        .append('canvas')
        .attr('width', width)
        .attr('height', height)
        .style('position', 'absolute')
        .style('top', '0')
        .style('left', '0')
        .style('pointer-events', 'none')
        .style('display', 'none')
        .style('width', '100%')
        .style('height', '100%');
    
    context = canvas.node().getContext('2d');
    
    // Hidden canvas for hit detection
    hiddenCanvas = document.createElement('canvas');
    hiddenCanvas.width = width;
    hiddenCanvas.height = height;
    hiddenContext = hiddenCanvas.getContext('2d');
    
    // Handle window resize
    window.addEventListener('resize', handleResize);
    
    // Add zoom behavior with level-of-detail
    const zoom = d3.zoom()
        .scaleExtent([0.01, 50])
        .on('zoom', (event) => {
            currentZoom = event.transform.k;
            g.attr('transform', event.transform);
            
            // Update zoom info
            document.getElementById('zoomLevel').textContent = Math.round(currentZoom * 100) + '%';
            document.getElementById('visibleNodes').textContent = currentNodes.length;
            
            // Switch rendering mode based on zoom and node count
            updateRenderingMode();
            
            // Update level of detail
            updateLevelOfDetail();
        });
    
    svg.call(zoom);
    
    // Create main group for transformation
    g = svg.append('g');
    
    // Add arrow marker for directed edges
    svg.append('defs').append('marker')
        .attr('id', 'arrowhead')
        .attr('viewBox', '-0 -5 10 10')
        .attr('refX', 30)
        .attr('refY', 0)
        .attr('orient', 'auto')
        .attr('markerWidth', 10)
        .attr('markerHeight', 10)
        .append('path')
        .attr('d', 'M 0,-5 L 10,0 L 0,5')
        .attr('fill', '#666');
}

async function loadStates() {
    try {
        const response = await fetch('/api/states');
        const data = await response.json();
        states = data.states;
        document.getElementById('totalStates').textContent = states.length;
        
        if (states.length > 0) {
            document.getElementById('nextBtn').disabled = states.length <= 1;
            displayState(0);
        }
    } catch (error) {
        console.error('Error loading states:', error);
    }
}

function displayState(index) {
    if (index < 0 || index >= states.length) return;
    
    currentStateIndex = index;
    const state = states[index];
    
    // Update info panel
    document.getElementById('timestamp').textContent = state.timestamp || '-';
    document.getElementById('iteration').textContent = state.iterationnumber || '0';
    document.getElementById('querypath').textContent = state.current_querypath || '-';
    document.getElementById('currentState').textContent = index + 1;
    
    // Update navigation buttons
    document.getElementById('prevBtn').disabled = index === 0;
    document.getElementById('nextBtn').disabled = index === states.length - 1;
    
    // Draw the graph
    drawGraph(state.current_graph);
}

function updateRenderingMode() {
    const nodeCount = currentNodes.length;
    const shouldUseCanvas = nodeCount > 500 || (currentZoom < 0.3 && nodeCount > 100);
    
    if (shouldUseCanvas !== useCanvas) {
        useCanvas = shouldUseCanvas;
        
        if (useCanvas) {
            // Switch to canvas
            canvas.style('display', 'block');
            nodeGroup.style('display', 'none');
            linkGroup.style('display', 'none');
            document.getElementById('renderMode').textContent = 'Canvas';
            renderCanvas();
        } else {
            // Switch to SVG
            canvas.style('display', 'none');
            nodeGroup.style('display', null);
            linkGroup.style('display', null);
            document.getElementById('renderMode').textContent = 'SVG';
        }
    } else if (useCanvas) {
        renderCanvas();
    }
}

function handleResize() {
    const width = window.innerWidth;
    const height = window.innerHeight;
    
    // Update SVG dimensions
    svg.attr('width', width).attr('height', height);
    
    // Update canvas dimensions
    if (canvas) {
        canvas.attr('width', width).attr('height', height);
    }
    
    if (hiddenCanvas) {
        hiddenCanvas.width = width;
        hiddenCanvas.height = height;
    }
    
    // Update force center
    if (simulation) {
        simulation.force('center', d3.forceCenter(width / 2, height / 2));
        simulation.alpha(0.3).restart();
    }
}

function renderCanvas() {
    const width = window.innerWidth;
    const height = window.innerHeight;
    
    // Clear canvas
    context.clearRect(0, 0, width, height);
    context.save();
    
    // Apply zoom transform
    const transform = d3.zoomTransform(svg.node());
    context.translate(transform.x, transform.y);
    context.scale(transform.k, transform.k);
    
    // Calculate viewport bounds for culling
    const viewportBounds = {
        left: -transform.x / transform.k - 50,
        right: (width - transform.x) / transform.k + 50,
        top: -transform.y / transform.k - 50,
        bottom: (height - transform.y) / transform.k + 50
    };
    
    // Determine detail level
    const showLabels = currentZoom > 0.5;
    const showEdges = currentZoom > 0.1;
    const showClusters = currentZoom < 0.05 && currentNodes.length > 1000;
    const nodeRadius = Math.max(2, Math.min(30, 30 * currentZoom));
    
    // Parse query path for highlighting
    const queryPath = states[currentStateIndex]?.current_querypath || '';
    const { pathEdges, pathNodes } = parseQueryPath(queryPath, currentEdges);
    
    // If extremely zoomed out with many nodes, show clusters
    if (showClusters) {
        const clusters = getNodeClusters();
        if (clusters) {
            clusters.forEach(cluster => {
                // Draw cluster bubble
                const radius = Math.sqrt(cluster.count) * 10;
                context.fillStyle = 'rgba(100, 100, 200, 0.3)';
                context.beginPath();
                context.arc(cluster.x, cluster.y, radius, 0, 2 * Math.PI);
                context.fill();
                
                // Draw cluster count
                context.fillStyle = '#333';
                context.font = '14px sans-serif';
                context.textAlign = 'center';
                context.textBaseline = 'middle';
                context.fillText(cluster.count.toString(), cluster.x, cluster.y);
            });
            context.restore();
            return;
        }
    }
    
    // Count visible nodes
    let visibleNodeCount = 0;
    
    // Draw edges if zoom is sufficient (with culling)
    if (showEdges) {
        currentEdges.forEach(edge => {
            if (edge.source.x && edge.target.x) {
                // Simple culling check
                if ((edge.source.x > viewportBounds.left && edge.source.x < viewportBounds.right) ||
                    (edge.target.x > viewportBounds.left && edge.target.x < viewportBounds.right)) {
                    
                    // Check if this edge is in the path
                    const edgeKey = `${edge.source.id || edge.source}-${edge.target.id || edge.target}-${edge.door}`;
                    const isPathEdge = pathEdges.has(edgeKey);
                    
                    // Style based on whether it's a path edge
                    if (isPathEdge) {
                        context.strokeStyle = '#ff4444';
                        context.lineWidth = Math.max(2, 4 / currentZoom);
                    } else {
                        context.strokeStyle = 'rgba(153, 153, 153, 0.3)';
                        context.lineWidth = Math.max(0.5, 1 * currentZoom);
                    }
                    
                    context.beginPath();
                    context.moveTo(edge.source.x, edge.source.y);
                    context.lineTo(edge.target.x, edge.target.y);
                    context.stroke();
                }
            }
        });
    }
    
    // Draw nodes (with viewport culling)
    currentNodes.forEach(node => {
        if (!node.x || !node.y) return;
        
        // Viewport culling
        if (node.x < viewportBounds.left || node.x > viewportBounds.right ||
            node.y < viewportBounds.top || node.y > viewportBounds.bottom) {
            return;
        }
        
        visibleNodeCount++;
        
        // Check if this node is in the path
        const isPathNode = pathNodes.has(node.id);
        
        // Use constant size for path nodes
        const actualRadius = isPathNode ? 20 / currentZoom : nodeRadius;
        
        // Draw node circle
        context.fillStyle = labelColors[node.label] || '#ccc';
        context.beginPath();
        context.arc(node.x, node.y, actualRadius, 0, 2 * Math.PI);
        context.fill();
        
        // Draw border (thicker for path nodes)
        context.strokeStyle = isPathNode ? '#ff0000' : '#333';
        context.lineWidth = isPathNode ? 4 / currentZoom : Math.max(0.5, 2 * currentZoom);
        context.stroke();
        
        // Add glow effect for path nodes
        if (isPathNode) {
            context.shadowColor = 'rgba(255, 0, 0, 0.6)';
            context.shadowBlur = 10 / currentZoom;
            context.strokeStyle = '#ff0000';
            context.lineWidth = 2 / currentZoom;
            context.stroke();
            context.shadowBlur = 0;
        }
        
        // Draw labels if zoomed in enough
        if (showLabels) {
            context.fillStyle = '#000';
            context.font = `${Math.max(8, 12 * currentZoom)}px sans-serif`;
            context.textAlign = 'center';
            context.textBaseline = 'middle';
            context.fillText(node.id, node.x, node.y);
        }
    });
    
    // Update visible node count
    document.getElementById('visibleNodes').textContent = visibleNodeCount;
    
    context.restore();
}

function updateLevelOfDetail() {
    if (useCanvas) return; // Canvas handles its own LOD
    
    // Parse query path for highlighting
    const queryPath = states[currentStateIndex]?.current_querypath || '';
    const { pathEdges, pathNodes } = parseQueryPath(queryPath, currentEdges);
    
    // Update SVG elements based on zoom level
    const showLabels = currentZoom > 0.3;
    const showEdgeLabels = currentZoom > 0.5;
    const showNodeDetails = currentZoom > 0.2;
    
    // Toggle node labels
    nodeGroup.selectAll('.node-id')
        .style('display', showLabels ? null : 'none');
    
    nodeGroup.selectAll('.node-label')
        .style('display', showNodeDetails ? null : 'none');
    
    // Toggle edge labels
    linkGroup.selectAll('text')
        .style('display', showEdgeLabels ? null : 'none');
    
    // Adjust node size based on zoom - but keep path nodes constant size
    nodeGroup.selectAll('path')
        .attr('d', d => {
            if (pathNodes.has(d.id)) {
                // Path nodes stay constant visual size
                return hexagonPath(20 / currentZoom);
            } else {
                // Regular nodes scale with zoom
                if (currentZoom < 0.5) {
                    return hexagonPath(Math.max(10, 30 * currentZoom));
                } else {
                    return hexagonPath(30);
                }
            }
        });
    
    // Update edge styling based on zoom and path
    linkGroup.selectAll('line')
        .attr('stroke-width', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            if (pathEdges.has(edgeKey)) {
                // Path edges stay constant visual width
                return Math.max(2, 4 / currentZoom);
            } else {
                // Regular edges scale down at low zoom
                if (currentZoom < 0.3) {
                    return 1;
                } else {
                    return 2;
                }
            }
        })
        .attr('opacity', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? 1 : (currentZoom < 0.3 ? 0.3 : 0.6);
        });
}

function drawGraph(graphData) {
    if (!graphData || !graphData.nodes) {
        console.log('No graph data');
        return;
    }
    
    const newNodes = graphData.nodes || [];
    const newEdges = graphData.edges || [];
    
    // Check if this is the first draw or a complete reset
    const isInitialDraw = !linkGroup || !nodeGroup;
    
    if (isInitialDraw) {
        // Clear and create groups for the first time
        g.selectAll('*').remove();
        linkGroup = g.append('g').attr('class', 'links');
        nodeGroup = g.append('g').attr('class', 'nodes');
        currentNodes = [];
        currentEdges = [];
        nodeById.clear();
    }
    
    // Find truly new nodes and edges
    const existingNodeIds = new Set(currentNodes.map(n => n.id));
    const nodesToAdd = newNodes.filter(n => !existingNodeIds.has(n.id));
    
    const existingEdgeKeys = new Set(currentEdges.map(e => 
        `${e.source.id || e.source}-${e.target.id || e.target}-${e.door}`
    ));
    const edgesToAdd = newEdges.filter(e => {
        const key = `${e.source}-${e.target}-${e.door}`;
        return !existingEdgeKeys.has(key);
    });
    
    // Update counts
    document.getElementById('nodecount').textContent = newNodes.length;
    document.getElementById('edgecount').textContent = newEdges.length;
    
    // If nothing new, just update highlighting
    if (nodesToAdd.length === 0 && edgesToAdd.length === 0 && !isInitialDraw) {
        updateHighlighting();
        return;
    }
    
    // Add new nodes to current data
    nodesToAdd.forEach(node => {
        const nodeCopy = {...node};
        currentNodes.push(nodeCopy);
        nodeById.set(node.id, nodeCopy);
    });
    
    // Add new edges to current data (with node references)
    edgesToAdd.forEach(edge => {
        const edgeCopy = {
            ...edge,
            source: nodeById.get(edge.source) || edge.source,
            target: nodeById.get(edge.target) || edge.target
        };
        currentEdges.push(edgeCopy);
    });
    
    const nodes = currentNodes;
    const edges = currentEdges;
    
    // Update counts
    document.getElementById('nodecount').textContent = nodes.length;
    document.getElementById('edgecount').textContent = edges.length;
    
    // Parse the query path to highlight edges and nodes
    const queryPath = states[currentStateIndex].current_querypath || '';
    const { pathEdges, pathNodes } = parseQueryPath(queryPath, edges);
    
    // Create or update force simulation
    if (!simulation || isInitialDraw) {
        simulation = d3.forceSimulation(nodes)
            .force('link', d3.forceLink(edges)
                .id(d => d.id)
                .distance(100))
            .force('charge', d3.forceManyBody().strength(-500))
            .force('center', d3.forceCenter(
                window.innerWidth / 2,
                window.innerHeight / 2))
            .force('collision', d3.forceCollide().radius(40));
    } else {
        // Update existing simulation with new nodes/edges
        simulation.nodes(nodes);
        simulation.force('link').links(edges);
        simulation.alpha(0.3).restart();
    }
    
    // Update edges - bind to current data
    const link = linkGroup.selectAll('g.link-group')
        .data(edges, d => `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`);
    
    // Remove old edges
    link.exit().remove();
    
    // Add new edges
    const linkEnter = link.enter().append('g')
        .attr('class', 'link-group');
    
    // Edge lines
    const linkLine = linkEnter.append('line')
        .attr('class', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? 'link highlighted-edge' : 'link';
        })
        .attr('stroke', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? '#ff4444' : '#999';
        })
        .attr('stroke-width', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? 4 : 2;
        })
        .attr('marker-end', 'url(#arrowhead)');
    
    // Edge labels (door numbers)
    const linkLabel = linkEnter.append('text')
        .attr('class', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? 'link-label highlighted-label' : 'link-label';
        })
        .text(d => d.door !== undefined ? d.door : '')
        .attr('font-size', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? '16px' : '12px';
        })
        .attr('font-weight', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? 'bold' : 'normal';
        })
        .attr('fill', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? '#ff0000' : '#666';
        })
        .attr('text-anchor', 'middle');
    
    // Update nodes - bind to current data
    const node = nodeGroup.selectAll('g.node-group')
        .data(nodes, d => d.id);
    
    // Remove old nodes
    node.exit().remove();
    
    // Add new nodes
    const nodeEnter = node.enter().append('g')
        .attr('class', 'node-group')
        .call(d3.drag()
            .on('start', dragstarted)
            .on('drag', dragged)
            .on('end', dragended));
    
    // Draw hexagons for new nodes
    nodeEnter.append('path')
        .attr('d', hexagonPath(30))
        .attr('fill', d => labelColors[d.label] || '#ccc')
        .attr('stroke', d => pathNodes.has(d.id) ? '#ff0000' : '#333')
        .attr('stroke-width', d => pathNodes.has(d.id) ? 4 : 2)
        .attr('class', d => pathNodes.has(d.id) ? 'node-hexagon path-node' : 'node-hexagon');
    
    // Node labels (room ID)
    nodeEnter.append('text')
        .attr('class', 'node-id')
        .text(d => d.id)
        .attr('text-anchor', 'middle')
        .attr('dy', '-5')
        .attr('font-size', '14px')
        .attr('font-weight', 'bold');
    
    // Node labels (room label)
    nodeEnter.append('text')
        .attr('class', 'node-label')
        .text(d => d.label)
        .attr('text-anchor', 'middle')
        .attr('dy', '10')
        .attr('font-size', '16px')
        .attr('fill', '#333');
    
    // Merge enter and update selections
    const allLinks = linkGroup.selectAll('g.link-group');
    const allNodes = nodeGroup.selectAll('g.node-group');
    
    // Update highlighting for all elements
    updateHighlighting();
    
    // Check if we should switch rendering modes
    updateRenderingMode();
    
    // Update positions on simulation tick
    simulation.on('tick', () => {
        if (useCanvas) {
            renderCanvas();
        } else {
        linkGroup.selectAll('line')
            .attr('x1', d => d.source.x)
            .attr('y1', d => d.source.y)
            .attr('x2', d => d.target.x)
            .attr('y2', d => d.target.y);
        
        linkGroup.selectAll('text')
            .attr('x', d => (d.source.x + d.target.x) / 2)
            .attr('y', d => (d.source.y + d.target.y) / 2);
        
            nodeGroup.selectAll('g.node-group')
                .attr('transform', d => `translate(${d.x},${d.y})`);
        }
    });
}

function updateHighlighting() {
    // Parse the query path to highlight edges and nodes
    const queryPath = states[currentStateIndex]?.current_querypath || '';
    const { pathEdges, pathNodes } = parseQueryPath(queryPath, currentEdges);
    
    // Update edge highlighting
    linkGroup.selectAll('line')
        .attr('class', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? 'link highlighted-edge' : 'link';
        })
        .attr('stroke', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? '#ff4444' : '#999';
        })
        .attr('stroke-width', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? 4 : 2;
        });
    
    // Update edge label highlighting
    linkGroup.selectAll('text')
        .attr('class', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? 'link-label highlighted-label' : 'link-label';
        })
        .attr('font-size', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? '16px' : '12px';
        })
        .attr('font-weight', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? 'bold' : 'normal';
        })
        .attr('fill', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.has(edgeKey) ? '#ff0000' : '#666';
        });
    
    // Update node highlighting with constant visual stroke width for path nodes
    nodeGroup.selectAll('path')
        .attr('stroke', d => pathNodes.has(d.id) ? '#ff0000' : '#333')
        .attr('stroke-width', d => {
            if (pathNodes.has(d.id)) {
                // Path nodes have constant visual stroke width
                return 4 / currentZoom;
            } else {
                return 2;
            }
        })
        .attr('class', d => pathNodes.has(d.id) ? 'node-hexagon path-node' : 'node-hexagon');
}

function hexagonPath(radius) {
    const angles = d3.range(0, 2 * Math.PI, Math.PI / 3);
    const hexagon = angles.map(angle => {
        return [radius * Math.cos(angle), radius * Math.sin(angle)];
    });
    return 'M' + hexagon.join('L') + 'Z';
}

// Drag functions
function dragstarted(event, d) {
    if (!event.active) simulation.alphaTarget(0.3).restart();
    d.fx = d.x;
    d.fy = d.y;
}

function dragged(event, d) {
    d.fx = event.x;
    d.fy = event.y;
}

function dragended(event, d) {
    if (!event.active) simulation.alphaTarget(0);
    d.fx = null;
    d.fy = null;
}

// Navigation functions
function previousState() {
    if (currentStateIndex > 0) {
        displayState(currentStateIndex - 1);
    }
}

function nextState() {
    if (currentStateIndex < states.length - 1) {
        displayState(currentStateIndex + 1);
    }
}

function togglePlay() {
    isPlaying = !isPlaying;
    const playBtn = document.getElementById('playBtn');
    
    if (isPlaying) {
        playBtn.textContent = '⏸️ Pause';
        const speed = parseInt(document.getElementById('speedSlider').value);
        
        playInterval = setInterval(() => {
            if (currentStateIndex < states.length - 1) {
                nextState();
            } else {
                togglePlay(); // Stop at the end
            }
        }, speed);
    } else {
        playBtn.textContent = '▶️ Play';
        if (playInterval) {
            clearInterval(playInterval);
            playInterval = null;
        }
    }
}

function resetView() {
    // Reset zoom and center
    const zoom = d3.zoom();
    svg.transition().duration(750).call(
        zoom.transform,
        d3.zoomIdentity
    );
    
    currentZoom = 1;
    updateRenderingMode();
    updateLevelOfDetail();
    
    // Restart simulation
    if (simulation) {
        simulation.alpha(1).restart();
    }
}

// Add cluster visualization for extreme zoom out
function getNodeClusters() {
    if (currentZoom > 0.1 || currentNodes.length < 100) {
        return null; // Don't cluster at this zoom/size
    }
    
    // Simple grid-based clustering
    const clusterSize = 100 / currentZoom;
    const clusters = new Map();
    
    currentNodes.forEach(node => {
        if (!node.x || !node.y) return;
        
        const clusterX = Math.floor(node.x / clusterSize);
        const clusterY = Math.floor(node.y / clusterSize);
        const key = `${clusterX},${clusterY}`;
        
        if (!clusters.has(key)) {
            clusters.set(key, {
                x: clusterX * clusterSize + clusterSize / 2,
                y: clusterY * clusterSize + clusterSize / 2,
                count: 0,
                nodes: []
            });
        }
        
        const cluster = clusters.get(key);
        cluster.count++;
        cluster.nodes.push(node);
    });
    
    return clusters;
}

let selectedFileData = null;

function handleFileSelect(event) {
    const file = event.target.files[0];
    if (file) {
        document.getElementById('selectedFile').textContent = file.name;
        document.getElementById('loadBtn').disabled = false;
        
        // Read the file
        const reader = new FileReader();
        reader.onload = function(e) {
            selectedFileData = e.target.result;
        };
        reader.readAsText(file);
    }
}

async function loadSelectedFile() {
    if (!selectedFileData) return;
    
    const statusEl = document.getElementById('loadStatus');
    
    try {
        statusEl.textContent = 'Processing...';
        statusEl.style.color = '#666';
        
        // Determine if it's JSON or JSONL
        const isJsonl = selectedFileData.includes('\n{');
        
        const response = await fetch('/api/load_data', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ 
                data: selectedFileData,
                format: isJsonl ? 'jsonl' : 'json'
            })
        });
        
        const result = await response.json();
        
        if (result.success) {
            statusEl.textContent = `✓ Loaded ${result.states_loaded} states`;
            statusEl.style.color = 'green';
            await loadStates();
        } else {
            statusEl.textContent = `✗ ${result.message}`;
            statusEl.style.color = 'red';
        }
    } catch (error) {
        statusEl.textContent = `✗ Error: ${error.message}`;
        statusEl.style.color = 'red';
    }
}

async function loadFile() {
    const filepath = document.getElementById('filepath').value;
    const statusEl = document.getElementById('loadStatus');
    
    try {
        statusEl.textContent = 'Loading...';
        statusEl.style.color = '#666';
        
        const response = await fetch('/api/load', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ filepath: filepath })
        });
        
        const result = await response.json();
        
        if (result.success) {
            statusEl.textContent = `✓ Loaded ${result.states_loaded} states`;
            statusEl.style.color = 'green';
            await loadStates();
        } else {
            statusEl.textContent = result.message;
            statusEl.style.color = 'orange';
            await loadStates();
        }
    } catch (error) {
        statusEl.textContent = `✗ Error: ${error.message}`;
        statusEl.style.color = 'red';
    }
}

// Keyboard shortcuts
document.addEventListener('keydown', function(e) {
    if (e.key === 'ArrowLeft') {
        previousState();
    } else if (e.key === 'ArrowRight') {
        nextState();
    } else if (e.key === ' ') {
        e.preventDefault();
        togglePlay();
    }
});

// Live update functions
function startLiveUpdates() {
    // Close existing connection if any
    if (eventSource) {
        eventSource.close();
    }
    
    // Create new EventSource for Server-Sent Events
    eventSource = new EventSource('/api/stream');
    
    eventSource.onmessage = function(event) {
        const data = JSON.parse(event.data);
        
        // Skip heartbeat messages
        if (data.heartbeat) {
            return;
        }
        
        // Add new state
        if (data.state) {
            states.push(data.state);
            document.getElementById('totalStates').textContent = states.length;
            
            // Show live indicator
            const indicator = document.getElementById('liveIndicator');
            indicator.classList.remove('hidden');
            setTimeout(() => {
                indicator.classList.add('pulse');
                setTimeout(() => {
                    indicator.classList.remove('pulse');
                }, 500);
            }, 10);
            
            // Auto-follow to new state if enabled
            if (autoFollow && !isPlaying) {
                displayState(states.length - 1);
            }
            
            // Update navigation buttons
            if (currentStateIndex === states.length - 2) {
                document.getElementById('nextBtn').disabled = false;
            }
        }
    };
    
    eventSource.onerror = function(error) {
        console.error('SSE error:', error);
        // Reconnect after 3 seconds
        setTimeout(() => {
            startLiveUpdates();
        }, 3000);
    };
}

function toggleAutoFollow() {
    autoFollow = !autoFollow;
    const btn = document.getElementById('autoFollowBtn');
    
    if (autoFollow) {
        btn.textContent = '📍 Auto-Follow: ON';
        btn.classList.remove('auto-follow-off');
        btn.classList.add('auto-follow-on');
        
        // Jump to latest state
        if (states.length > 0) {
            displayState(states.length - 1);
        }
    } else {
        btn.textContent = '📍 Auto-Follow: OFF';
        btn.classList.remove('auto-follow-on');
        btn.classList.add('auto-follow-off');
    }
}

async function toggleAutoGeneration() {
    autoGenerate = !autoGenerate;
    const btn = document.getElementById('autoGenBtn');
    
    if (autoGenerate) {
        btn.textContent = '🤖 Auto-Generate: ON';
        btn.classList.remove('auto-gen-off');
        btn.classList.add('auto-gen-on');
        
        // Start auto-generation
        const response = await fetch('/api/auto_generate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ action: 'start' })
        });
        
        if (!response.ok) {
            console.error('Failed to start auto-generation');
            autoGenerate = false;
            btn.textContent = '🤖 Auto-Generate: OFF';
            btn.classList.remove('auto-gen-on');
            btn.classList.add('auto-gen-off');
        }
    } else {
        btn.textContent = '🤖 Auto-Generate: OFF';
        btn.classList.remove('auto-gen-on');
        btn.classList.add('auto-gen-off');
        
        // Stop auto-generation
        await fetch('/api/auto_generate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ action: 'stop' })
        });
    }
}

// Alternative polling method (if SSE doesn't work)
function startPolling() {
    setInterval(async () => {
        try {
            const response = await fetch('/api/check_updates');
            const data = await response.json();
            
            if (data.new_states && data.new_states.length > 0) {
                // Add new states
                states.push(...data.new_states);
                document.getElementById('totalStates').textContent = states.length;
                
                // Auto-follow if enabled
                if (autoFollow && !isPlaying) {
                    displayState(states.length - 1);
                }
            }
        } catch (error) {
            console.error('Polling error:', error);
        }
    }, 1000); // Check every second
}