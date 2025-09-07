// Graph Visualization with D3.js
let currentStateIndex = 0;
let states = [];
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
function parseQueryPath(queryPath, edges, pathType = 'search') {
    if (!queryPath) return { pathEdges: new Set(), pathNodes: new Set(), pathType };
    
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
    
    return { pathEdges, pathNodes, pathType };
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
    
    // Add arrow markers for directed edges (larger size)
    const defs = svg.append('defs');
    
    // Default arrow
    defs.append('marker')
        .attr('id', 'arrowhead')
        .attr('viewBox', '-0 -5 10 10')
        .attr('refX', 35)
        .attr('refY', 0)
        .attr('orient', 'auto')
        .attr('markerWidth', 15)
        .attr('markerHeight', 15)
        .append('path')
        .attr('d', 'M 0,-5 L 10,0 L 0,5')
        .attr('fill', '#666');
    
    // Red arrow for search paths
    defs.append('marker')
        .attr('id', 'arrowhead-search')
        .attr('viewBox', '-0 -5 10 10')
        .attr('refX', 35)
        .attr('refY', 0)
        .attr('orient', 'auto')
        .attr('markerWidth', 15)
        .attr('markerHeight', 15)
        .append('path')
        .attr('d', 'M 0,-5 L 10,0 L 0,5')
        .attr('fill', '#ff4444');
    
    // Green arrow for ping paths
    defs.append('marker')
        .attr('id', 'arrowhead-ping')
        .attr('viewBox', '-0 -5 10 10')
        .attr('refX', 35)
        .attr('refY', 0)
        .attr('orient', 'auto')
        .attr('markerWidth', 15)
        .attr('markerHeight', 15)
        .append('path')
        .attr('d', 'M 0,-5 L 10,0 L 0,5')
        .attr('fill', '#00ff00');
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
    
    // Show both ping and search paths
    let pathDisplay = '';
    if (state.ping_path) {
        pathDisplay += `🟢 Ping: ${state.ping_path} `;
    }
    if (state.search_path) {
        pathDisplay += `🔴 Search: ${state.search_path}`;
    }
    if (!pathDisplay && state.current_querypath) {
        pathDisplay = state.current_querypath;
    }
    document.getElementById('querypath').textContent = pathDisplay || '-';
    document.getElementById('currentState').textContent = index + 1;
    
    // Update navigation buttons
    document.getElementById('prevBtn').disabled = index === 0;
    document.getElementById('nextBtn').disabled = index === states.length - 1;
    document.getElementById('prev10Btn').disabled = index === 0;
    document.getElementById('next10Btn').disabled = index === states.length - 1;
    document.getElementById('startBtn').disabled = index === 0;
    document.getElementById('endBtn').disabled = index === states.length - 1;
    
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
    
    // Update center for layout
    // Nodes will be re-centered on next draw if needed
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
    
    // Parse both ping and search paths for highlighting
    const state = states[currentStateIndex] || {};
    const searchPath = state.search_path || state.current_querypath || '';
    const pingPath = state.ping_path || '';
    
    // Parse both paths
    const searchPathData = parseQueryPath(searchPath, currentEdges, 'search');
    const pingPathData = parseQueryPath(pingPath, currentEdges, 'ping');
    
    // Combine path data (ping takes precedence for coloring)
    const pathEdges = new Map();
    const pathNodes = new Map();
    
    // Add search paths (red)
    searchPathData.pathEdges.forEach(edge => pathEdges.set(edge, 'search'));
    searchPathData.pathNodes.forEach(node => pathNodes.set(node, 'search'));
    
    // Add ping paths (green) - these override search if there's overlap
    pingPathData.pathEdges.forEach(edge => pathEdges.set(edge, 'ping'));
    pingPathData.pathNodes.forEach(node => pathNodes.set(node, 'ping'));
    
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
                    const pathType = pathEdges.get(edgeKey);
                    const isPathEdge = !!pathType;
                    
                    // Style based on path type
                    if (pathType === 'ping') {
                        context.strokeStyle = '#00ff00';  // Green for ping
                        context.lineWidth = Math.max(2, 4 / currentZoom);
                    } else if (pathType === 'search') {
                        context.strokeStyle = '#ff4444';  // Red for search
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
        const pathType = pathNodes.get(node.id);
        const isPathNode = !!pathType;
        
        // Use constant size for path nodes
        const actualRadius = isPathNode ? 20 / currentZoom : nodeRadius;
        
        // Draw node circle
        context.fillStyle = labelColors[node.label] || '#ccc';
        context.beginPath();
        context.arc(node.x, node.y, actualRadius, 0, 2 * Math.PI);
        context.fill();
        
        // Draw border (color based on path type)
        if (pathType === 'ping') {
            context.strokeStyle = '#00ff00';  // Green for ping
        } else if (pathType === 'search') {
            context.strokeStyle = '#ff0000';  // Red for search
        } else {
            context.strokeStyle = '#333';
        }
        context.lineWidth = isPathNode ? 4 / currentZoom : Math.max(0.5, 2 * currentZoom);
        context.stroke();
        
        // Add glow effect for path nodes
        if (isPathNode) {
            if (pathType === 'ping') {
                context.shadowColor = 'rgba(0, 255, 0, 0.6)';
                context.strokeStyle = '#00ff00';
            } else {
                context.shadowColor = 'rgba(255, 0, 0, 0.6)';
                context.strokeStyle = '#ff0000';
            }
            context.shadowBlur = 10 / currentZoom;
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
    
    // Parse both ping and search paths for highlighting
    const state = states[currentStateIndex] || {};
    const searchPath = state.search_path || state.current_querypath || '';
    const pingPath = state.ping_path || '';
    
    // Parse both paths
    const searchPathData = parseQueryPath(searchPath, currentEdges, 'search');
    const pingPathData = parseQueryPath(pingPath, currentEdges, 'ping');
    
    // Combine path data (ping takes precedence for coloring)
    const pathEdges = new Map();
    const pathNodes = new Map();
    
    // Add search paths (red)
    searchPathData.pathEdges.forEach(edge => pathEdges.set(edge, 'search'));
    searchPathData.pathNodes.forEach(node => pathNodes.set(node, 'search'));
    
    // Add ping paths (green) - these override search if there's overlap
    pingPathData.pathEdges.forEach(edge => pathEdges.set(edge, 'ping'));
    pingPathData.pathNodes.forEach(node => pathNodes.set(node, 'ping'));
    
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
            if (pathNodes.get(d.id)) {
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
            return pathEdges.get(edgeKey) ? 1 : (currentZoom < 0.3 ? 0.3 : 0.6);
        });
}

function drawGraph(graphData) {
    if (!graphData || !graphData.nodes) {
        console.log('No graph data');
        return;
    }
    
    // Clear everything and redraw from scratch
    g.selectAll('*').remove();
    linkGroup = g.append('g').attr('class', 'links');
    nodeGroup = g.append('g').attr('class', 'nodes');
    
    // Get nodes and edges from current state
    currentNodes = (graphData.nodes || []).map(node => ({...node}));
    currentEdges = (graphData.edges || []).map(edge => ({...edge}));
    
    // Rebuild nodeById map
    nodeById.clear();
    currentNodes.forEach(node => {
        nodeById.set(node.id, node);
    });
    
    // Build edges with node references
    currentEdges = currentEdges.map(edge => ({
        ...edge,
        source: nodeById.get(edge.source) || edge.source,
        target: nodeById.get(edge.target) || edge.target
    }));
    
    const nodes = currentNodes;
    const edges = currentEdges;
    
    // Update counts
    document.getElementById('nodecount').textContent = nodes.length;
    document.getElementById('edgecount').textContent = edges.length;
    
    // Parse both ping and search paths to highlight edges and nodes
    const state = states[currentStateIndex];
    const searchPath = state.search_path || state.current_querypath || '';
    const pingPath = state.ping_path || '';
    
    // Parse both paths
    const searchPathData = parseQueryPath(searchPath, edges, 'search');
    const pingPathData = parseQueryPath(pingPath, edges, 'ping');
    
    // Combine path data (ping takes precedence for coloring)
    const pathEdges = new Map();
    const pathNodes = new Map();
    
    // Add search paths (red)
    searchPathData.pathEdges.forEach(edge => pathEdges.set(edge, 'search'));
    searchPathData.pathNodes.forEach(node => pathNodes.set(node, 'search'));
    
    // Add ping paths (green) - these override search if there's overlap
    pingPathData.pathEdges.forEach(edge => pathEdges.set(edge, 'ping'));
    pingPathData.pathNodes.forEach(node => pathNodes.set(node, 'ping'));
    
    // Layout nodes without force simulation
    // Use a simple radial or grid layout
    const centerX = window.innerWidth / 2;
    const centerY = window.innerHeight / 2;
    
    // Position nodes in a hexagonal pattern if they don't have positions
    nodes.forEach((node, i) => {
        if (node.x === undefined || node.y === undefined) {
            if (node.id === 'START' || node.nodeId === '0') {
                // Start node at center
                node.x = centerX;
                node.y = centerY;
            } else {
                // Arrange other nodes in concentric hexagons
                const angle = (i / nodes.length) * 2 * Math.PI;
                const radius = 150 + Math.floor(i / 6) * 100;
                node.x = centerX + radius * Math.cos(angle);
                node.y = centerY + radius * Math.sin(angle);
            }
        }
    });
    
    // Draw all edges
    const linkGroups = linkGroup.selectAll('g.link-group')
        .data(edges)
        .enter()
        .append('g')
        .attr('class', 'link-group');
    
    // Edge lines
    linkGroups.append('line')
        .attr('class', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.get(edgeKey) ? 'link highlighted-edge' : 'link';
        })
        .attr('stroke', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            const pathType = pathEdges.get(edgeKey);
            if (pathType === 'ping') return '#00ff00';  // Green for ping
            if (pathType === 'search') return '#ff4444';  // Red for search
            return '#999';  // Default gray
        })
        .attr('stroke-width', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.get(edgeKey) ? 4 : 2;
        })
        .attr('marker-end', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            const pathType = pathEdges.get(edgeKey);
            if (pathType === 'ping') return 'url(#arrowhead-ping)';
            if (pathType === 'search') return 'url(#arrowhead-search)';
            return 'url(#arrowhead)';
        });
    
    // Edge labels (door numbers)
    linkGroups.append('text')
        .attr('class', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.get(edgeKey) ? 'link-label highlighted-label' : 'link-label';
        })
        .text(d => d.door !== undefined ? d.door : '')
        .attr('font-size', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.get(edgeKey) ? '16px' : '12px';
        })
        .attr('font-weight', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.get(edgeKey) ? 'bold' : 'normal';
        })
        .attr('fill', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.get(edgeKey) ? '#ff0000' : '#666';
        })
        .attr('text-anchor', 'middle');
    
    // Draw all nodes
    const nodeGroups = nodeGroup.selectAll('g.node-group')
        .data(nodes)
        .enter()
        .append('g')
        .attr('class', 'node-group')
        .attr('transform', d => `translate(${d.x},${d.y})`)
        .call(d3.drag()
            .on('start', dragstarted)
            .on('drag', dragged)
            .on('end', dragended));
    
    // Draw hexagons for nodes
    nodeGroups.append('path')
        .attr('d', hexagonPath(30))
        .attr('fill', d => labelColors[d.label] || '#ccc')
        .attr('stroke', d => {
            // Purple for special nodes with roomIndex
            if (d.roomIndex !== undefined && d.roomIndex !== null) return '#9f7aea';
            // Path coloring based on type
            const pathType = pathNodes.get(d.id);
            if (pathType === 'ping') return '#00ff00';  // Green for ping
            if (pathType === 'search') return '#ff0000';  // Red for search
            // Default
            return '#333';
        })
        .attr('stroke-width', d => {
            if (d.roomIndex !== undefined && d.roomIndex !== null) return 3;
            if (pathNodes.has(d.id) || pathNodes.get(d.id)) return 4;
            return 2;
        })
        .attr('class', d => {
            if (d.roomIndex !== undefined && d.roomIndex !== null) return 'node-hexagon special-node';
            const pathType = pathNodes.get(d.id);
            if (pathType) return `node-hexagon path-node ${pathType}-path`;
            return 'node-hexagon';
        });
    
    // Node labels (show nodeId if available, otherwise ID)
    nodeGroups.append('text')
        .attr('class', 'node-id')
        .text(d => d.nodeId || d.id)
        .attr('text-anchor', 'middle')
        .attr('dy', '-5')
        .attr('font-size', '14px')
        .attr('font-weight', 'bold');
    
    // Node labels (room label)
    nodeGroups.append('text')
        .attr('class', 'node-label')
        .text(d => d.label)
        .attr('text-anchor', 'middle')
        .attr('dy', '10')
        .attr('font-size', '16px')
        .attr('fill', '#333');
    
    // Room index indicator for special nodes
    nodeGroups.append('text')
        .attr('class', 'node-room-index')
        .attr('text-anchor', 'middle')
        .attr('dy', '30')
        .attr('font-size', '12px')
        .attr('font-weight', 'bold')
        .attr('fill', '#9f7aea')
        .text(d => d.roomIndex !== undefined && d.roomIndex !== null ? `[${d.roomIndex}]` : '');
    
    // Update link positions
    linkGroup.selectAll('line')
        .attr('x1', d => d.source.x)
        .attr('y1', d => d.source.y)
        .attr('x2', d => d.target.x)
        .attr('y2', d => d.target.y);
    
    linkGroup.selectAll('text')
        .attr('x', d => (d.source.x + d.target.x) / 2)
        .attr('y', d => (d.source.y + d.target.y) / 2);
    
    // Check if we should switch rendering modes
    updateRenderingMode();
    
    // Render canvas if needed
    if (useCanvas) {
        renderCanvas();
    }
}

function updateHighlighting() {
    // Parse both ping and search paths to highlight edges and nodes
    const state = states[currentStateIndex] || {};
    const searchPath = state.search_path || state.current_querypath || '';
    const pingPath = state.ping_path || '';
    
    // Parse both paths
    const searchPathData = parseQueryPath(searchPath, currentEdges, 'search');
    const pingPathData = parseQueryPath(pingPath, currentEdges, 'ping');
    
    // Combine path data (ping takes precedence for coloring)
    const pathEdges = new Map();
    const pathNodes = new Map();
    
    // Add search paths (red)
    searchPathData.pathEdges.forEach(edge => pathEdges.set(edge, 'search'));
    searchPathData.pathNodes.forEach(node => pathNodes.set(node, 'search'));
    
    // Add ping paths (green) - these override search if there's overlap
    pingPathData.pathEdges.forEach(edge => pathEdges.set(edge, 'ping'));
    pingPathData.pathNodes.forEach(node => pathNodes.set(node, 'ping'));
    
    // Update edge highlighting
    linkGroup.selectAll('line')
        .attr('class', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            const pathType = pathEdges.get(edgeKey);
            return pathType ? `link highlighted-edge ${pathType}-edge` : 'link';
        })
        .attr('stroke', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            const pathType = pathEdges.get(edgeKey);
            if (pathType === 'ping') return '#00ff00';  // Green for ping
            if (pathType === 'search') return '#ff4444';  // Red for search
            return '#999';  // Default gray
        })
        .attr('stroke-width', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.get(edgeKey) ? 4 : 2;
        });
    
    // Update edge label highlighting
    linkGroup.selectAll('text')
        .attr('class', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.get(edgeKey) ? 'link-label highlighted-label' : 'link-label';
        })
        .attr('font-size', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.get(edgeKey) ? '16px' : '12px';
        })
        .attr('font-weight', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.get(edgeKey) ? 'bold' : 'normal';
        })
        .attr('fill', d => {
            const edgeKey = `${d.source.id || d.source}-${d.target.id || d.target}-${d.door}`;
            return pathEdges.get(edgeKey) ? '#ff0000' : '#666';
        });
    
    // Update node highlighting with constant visual stroke width for path nodes
    nodeGroup.selectAll('path')
        .attr('stroke', d => {
            const pathType = pathNodes.get(d.id);
            if (pathType === 'ping') return '#00ff00';  // Green for ping
            if (pathType === 'search') return '#ff0000';  // Red for search
            return '#333';  // Default
        })
        .attr('stroke-width', d => {
            if (pathNodes.get(d.id)) {
                // Path nodes have constant visual stroke width
                return 4 / currentZoom;
            } else {
                return 2;
            }
        })
        .attr('class', d => {
            const pathType = pathNodes.get(d.id);
            if (pathType) return `node-hexagon path-node ${pathType}-path`;
            return 'node-hexagon';
        });
}

function hexagonPath(radius) {
    const angles = d3.range(0, 2 * Math.PI, Math.PI / 3);
    const hexagon = angles.map(angle => {
        return [radius * Math.cos(angle), radius * Math.sin(angle)];
    });
    return 'M' + hexagon.join('L') + 'Z';
}

// Drag functions (without simulation)
function dragstarted(event, d) {
    d3.select(this).raise();
}

function dragged(event, d) {
    d.x = event.x;
    d.y = event.y;
    
    // Update node position
    d3.select(this)
        .attr('transform', `translate(${d.x},${d.y})`);
    
    // Update connected edges
    linkGroup.selectAll('line')
        .filter(edge => edge.source.id === d.id || edge.target.id === d.id)
        .attr('x1', edge => edge.source.x)
        .attr('y1', edge => edge.source.y)
        .attr('x2', edge => edge.target.x)
        .attr('y2', edge => edge.target.y);
    
    linkGroup.selectAll('text')
        .filter(edge => edge.source.id === d.id || edge.target.id === d.id)
        .attr('x', edge => (edge.source.x + edge.target.x) / 2)
        .attr('y', edge => (edge.source.y + edge.target.y) / 2);
}

function dragended(event, d) {
    // Nothing needed here without simulation
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

function skipStates(delta) {
    const newIndex = currentStateIndex + delta;
    if (newIndex >= 0 && newIndex < states.length) {
        displayState(newIndex);
    } else if (newIndex < 0) {
        displayState(0);
    } else if (newIndex >= states.length) {
        displayState(states.length - 1);
    }
}

function jumpToStart() {
    if (states.length > 0) {
        displayState(0);
    }
}

function jumpToEnd() {
    if (states.length > 0) {
        displayState(states.length - 1);
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
    
    // Re-center nodes
    const centerX = window.innerWidth / 2;
    const centerY = window.innerHeight / 2;
    currentNodes.forEach((node, i) => {
        if (node.id === 'START' || node.nodeId === '0') {
            node.x = centerX;
            node.y = centerY;
        } else {
            const angle = (i / currentNodes.length) * 2 * Math.PI;
            const radius = 150 + Math.floor(i / 6) * 100;
            node.x = centerX + radius * Math.cos(angle);
            node.y = centerY + radius * Math.sin(angle);
        }
    });
    
    // Redraw with new positions
    if (states[currentStateIndex]) {
        drawGraph(states[currentStateIndex].current_graph);
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
    } else if (e.key === 'PageUp') {
        e.preventDefault();
        skipStates(-10);
    } else if (e.key === 'PageDown') {
        e.preventDefault();
        skipStates(10);
    } else if (e.key === 'Home') {
        e.preventDefault();
        jumpToStart();
    } else if (e.key === 'End') {
        e.preventDefault();
        jumpToEnd();
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