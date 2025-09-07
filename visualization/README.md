# Graph Exploration Visualizer

A high-performance, interactive visualization tool for exploring graph structures with hexagonal room layouts. Built with D3.js and Flask, optimized for handling graphs from small (10 nodes) to massive (10,000+ nodes) scales.

## Features

### 🚀 Performance & Scalability
- **Dual Rendering Modes**: Automatically switches between SVG (small graphs) and Canvas (large graphs)
- **Level-of-Detail (LOD)**: Adjusts detail based on zoom level for optimal performance
- **Viewport Culling**: Only renders visible nodes and edges
- **Clustering**: Aggregates nodes when viewing 1000+ nodes at extreme zoom levels
- **Incremental Updates**: Adds new nodes/edges without full redraw

### 🎨 Visualization
- **Full Browser Window**: Maximizes visualization space with overlaid controls
- **Hexagonal Node Design**: Color-coded by labels (A=Red, B=Blue, C=Green, D=Yellow)
- **Path Highlighting**: Query paths remain visible at any zoom level with constant visual size
- **Force-Directed Layout**: Automatic graph arrangement with draggable nodes
- **Unique Node IDs**: Supports graphs with cycles and multiple nodes sharing the same label

### 📊 Data Handling
- **JSONL Support**: Streaming format for continuously growing files
- **Live Updates**: Real-time monitoring via Server-Sent Events (SSE)
- **File Upload**: Direct browser file selection or server path input
- **Auto-Generation**: Built-in graph generator for testing (creates realistic exploration patterns)

### 🎮 Controls
- **Navigation**: Previous/Next buttons with keyboard shortcuts (←/→ arrows)
- **Playback**: Auto-play with adjustable speed (spacebar to toggle)
- **Auto-Follow**: Automatically jump to newest states during live updates
- **Auto-Generate**: Create new exploration states every second
- **Zoom**: Mouse wheel zoom from 1% to 5000% with semantic details

## Installation

### Prerequisites
- Python 3.7+
- Modern web browser (Chrome, Firefox, Safari, Edge)

### Setup

1. Clone the repository:
```bash
cd visualization
```

2. Create a virtual environment (recommended):
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

## Running the Visualizer

1. Start the Flask server:
```bash
python app.py
```

2. Open your browser and navigate to:
```
http://127.0.0.1:9898
```

The server will:
- Create sample data if none exists
- Watch for file updates automatically
- Serve the visualization interface

## Data Format

The visualizer accepts both JSON and JSONL formats.

### JSONL Format (Recommended for streaming)
One JSON object per line:
```jsonl
{"timestamp": "2024-01-01T12:00:00", "iterationnumber": 0, "current_querypath": "", "current_graph": {"nodes": [{"id": "START", "label": "A"}], "edges": []}}
{"timestamp": "2024-01-01T12:00:01", "iterationnumber": 1, "current_querypath": "0", "current_graph": {"nodes": [{"id": "START", "label": "A"}, {"id": "0", "label": "B"}], "edges": [{"source": "START", "target": "0", "door": 0}]}}
```

### JSON Format (Array)
```json
[
  {
    "timestamp": "2024-01-01T12:00:00",
    "iterationnumber": 0,
    "current_querypath": "",
    "current_graph": {
      "nodes": [
        {"id": "START", "label": "A"},
        {"id": "0", "label": "B"}
      ],
      "edges": [
        {"source": "START", "target": "0", "door": 0}
      ]
    }
  }
]
```

### Field Descriptions

- **timestamp**: ISO format timestamp of the state
- **iterationnumber**: Sequential iteration number
- **current_querypath**: Path taken to reach current state (e.g., "0124" means doors 0→1→2→4)
- **nodes**: Array of nodes with:
  - `id`: Unique identifier (e.g., "START", "0", "124")
  - `label`: Display label (A, B, C, or D)
- **edges**: Array of connections with:
  - `source`: Source node ID
  - `target`: Target node ID
  - `door`: Door number (0-5)

## Usage Guide

### Loading Data

#### Option 1: File Upload
1. Click the green "📁 Choose File" button
2. Select a `.json` or `.jsonl` file
3. Click "Load File"

#### Option 2: Server Path
1. Enter the file path in the text field
2. Click "Load Path"

### Navigation Controls

| Control | Function | Keyboard |
|---------|----------|----------|
| ← Previous | Go to previous state | Left Arrow |
| Next → | Go to next state | Right Arrow |
| ▶️ Play | Auto-advance through states | Spacebar |
| 🔄 Reset View | Center graph and reset zoom | - |
| 📍 Auto-Follow | Follow newest states | - |
| 🤖 Auto-Generate | Generate new states | - |

### Zoom Levels & Performance

| Zoom | Nodes | Rendering | Details Shown |
|------|-------|-----------|---------------|
| >50% | Any | SVG | Full labels, edges, details |
| 30-50% | <500 | SVG | Reduced labels |
| 10-30% | <500 | SVG | Minimal details |
| <30% | >100 | Canvas | Optimized rendering |
| <10% | >500 | Canvas | Dots only |
| <5% | >1000 | Canvas | Clustered view |

### Live Updates

When a JSONL file is being written to:
1. The visualizer automatically detects new lines
2. "LIVE" indicator appears
3. With Auto-Follow enabled, view jumps to newest state
4. No need to reload - updates stream in real-time

### Generating Test Data

```bash
# Generate sample JSONL data
python generate_sample_data.py

# Generate specific number of states
python generate_sample_data.py 100

# Generate hexagon pattern
python generate_sample_data.py hexagon

# Append live state to existing file
python generate_sample_data.py append
```

## Performance Tips

### For Large Graphs (1000+ nodes)
- Zoom out to trigger Canvas mode
- Disable Auto-Follow when exploring manually
- Use viewport culling by focusing on specific areas
- Path highlighting maintains visibility at any scale

### For Real-Time Updates
- Use JSONL format for streaming
- Enable Auto-Follow to track latest changes
- Auto-Generate creates realistic exploration patterns
- SSE connection reconnects automatically if lost

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Main visualization interface |
| `/api/states` | GET | Get all loaded states |
| `/api/state/<id>` | GET | Get specific state by index |
| `/api/load` | POST | Load file from server path |
| `/api/load_data` | POST | Load uploaded file content |
| `/api/stream` | GET | SSE endpoint for live updates |
| `/api/auto_generate` | POST | Control auto-generation |
| `/api/check_updates` | GET | Poll for new states |

## Architecture

### Frontend
- **D3.js**: Force-directed graph layout and rendering
- **Canvas API**: High-performance rendering for large graphs
- **Server-Sent Events**: Real-time updates without polling

### Backend
- **Flask**: Lightweight Python web framework
- **Threading**: Background auto-generation
- **File Watching**: Incremental JSONL reading

### Optimization Techniques
1. **Incremental Rendering**: Only add/update changed elements
2. **Data Binding**: D3's efficient enter/update/exit pattern
3. **Viewport Culling**: Skip off-screen elements
4. **LOD System**: Reduce detail at low zoom levels
5. **Dual Renderers**: SVG for interaction, Canvas for scale

## Troubleshooting

### Issue: Graph not centering
**Solution**: Click "Reset View" or press 'R' to recenter

### Issue: Performance lag with many nodes
**Solution**: Zoom out to trigger Canvas mode (< 30% zoom)

### Issue: Can't see path highlights
**Solution**: Path nodes maintain constant size - they're always visible

### Issue: File not loading
**Solution**: Check file format (JSON/JSONL) and ensure valid structure

### Issue: Live updates not working
**Solution**: Check browser console for SSE connection status

## Browser Compatibility

| Browser | Version | Support |
|---------|---------|---------|
| Chrome | 90+ | ✅ Full |
| Firefox | 88+ | ✅ Full |
| Safari | 14+ | ✅ Full |
| Edge | 90+ | ✅ Full |

## License

This visualization tool is part of the ICFP 2025 Programming Contest solution.

## Contributing

Feel free to submit issues and enhancement requests!

## Acknowledgments

- D3.js for powerful data visualization
- Flask for simple and effective backend
- ICFP contest for the interesting graph exploration challenge