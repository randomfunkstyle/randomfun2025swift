#!/usr/bin/env python3
"""
Flask app for visualizing graph exploration states with D3.js
Supports JSONL format with live updates
"""
from flask import Flask, render_template, jsonify, request, Response
import json
import os
import time
import random
from threading import Thread, Lock, Event

app = Flask(__name__)
app.config['JSON_SORT_KEYS'] = False

# Global variables
graph_states = []
file_path = 'graph_states.jsonl'
last_position = 0
states_lock = Lock()
auto_generation_thread = None
auto_generation_stop = Event()
current_graph = {'nodes': [], 'edges': []}
explored_paths = set()
incremental_graph_state = {'nodes': {}, 'edges': {}}  # Track discovered nodes and edges across calls

def convert_incremental_format(data):
    """Convert single-node incremental format (test3.jsonl) to visualization format"""
    global incremental_graph_state
    
    current_node = data.get('graphAfter', {})
    query = data.get('query', '')
    result = data.get('result', [])
    is_ping = data.get('isPingQuery', False)
    
    # Extract clean query without brackets
    clean_query = ''.join(c for c in query if c.isdigit())
    
    # Map numeric labels to A,B,C,D
    label_map = {0: 'A', 1: 'B', 2: 'C', 3: 'D'}
    
    # Update the current node info
    node_id = str(current_node.get('nodeId', 0))
    incremental_graph_state['nodes'][node_id] = {
        'id': 'START' if current_node.get('roomIndex') == 0 else node_id,
        'nodeId': node_id,
        'label': label_map.get(current_node.get('roomLabel', 0), 'A'),
        'roomIndex': current_node.get('roomIndex')
    }
    
    # Process doors from current node to build edges
    doors = current_node.get('doors', [])
    for door_num, target_node_id in enumerate(doors):
        if target_node_id is not None:
            target_id = str(target_node_id)
            source = 'START' if node_id == '0' and current_node.get('roomIndex') == 0 else node_id
            
            # Add target node if not exists (will be updated when we visit it)
            if target_id not in incremental_graph_state['nodes']:
                incremental_graph_state['nodes'][target_id] = {
                    'id': target_id,
                    'nodeId': target_id,
                    'label': 'A'  # Default, will be updated when visited
                }
            
            # Add/update edge
            edge_key = f"{source}_{door_num}"
            incremental_graph_state['edges'][edge_key] = {
                'source': source,
                'target': target_id if target_id != '0' or not incremental_graph_state['nodes'].get(target_id, {}).get('roomIndex') == 0 else 'START',
                'door': door_num
            }
    
    # Build the path from query and result for visualization
    path_nodes = set()
    path_edges = set()
    
    if result and clean_query:
        current_pos = 'START' if node_id == '0' and current_node.get('roomIndex') == 0 else node_id
        path_nodes.add(current_pos)
        
        for i, door_char in enumerate(clean_query):
            if i < len(result):
                door_num = int(door_char)
                # Find where this door leads from current position
                edge_key = f"{current_pos}_{door_num}"
                if edge_key in incremental_graph_state['edges']:
                    edge = incremental_graph_state['edges'][edge_key]
                    next_pos = edge['target']
                    path_nodes.add(next_pos)
                    path_edges.add(f"{current_pos}-{next_pos}-{door_num}")
                    current_pos = next_pos
    
    # Convert to visualization format
    nodes = list(incremental_graph_state['nodes'].values())
    edges = list(incremental_graph_state['edges'].values())
    
    return {
        'timestamp': datetime.now().isoformat(),
        'iterationnumber': data.get('iterationnumber', 0),
        'current_querypath': clean_query if not is_ping else '',
        'ping_path': clean_query if is_ping else '',
        'search_path': clean_query if not is_ping else '',
        'isPingQuery': is_ping,
        'current_graph': {
            'nodes': nodes,
            'edges': edges
        },
        'path_nodes': list(path_nodes),  # For highlighting
        'path_edges': list(path_edges),  # For highlighting
        'graphBefore': data.get('graphBefore')
    }

def convert_node_format(data):
    """Convert node-based format to visualization format"""
    # Get graphAfter which contains the current state
    graph_after = data.get('graphAfter', [])
    
    # For test2.jsonl format - single node object (incremental)
    if isinstance(graph_after, dict):
        # Single node format - need to build graph from exploration
        return convert_incremental_format(data)
    
    # For test_nodes2.jsonl format - array of all nodes
    
    query = data.get('query', '')
    result = data.get('result', [])
    is_ping = data.get('isPingQuery', False)
    
    # Extract clean query without brackets
    clean_query = ''.join(c for c in query if c.isdigit())
    
    # Map numeric labels to A,B,C,D
    label_map = {0: 'A', 1: 'B', 2: 'C', 3: 'D'}
    
    # Build nodes from graphAfter
    nodes = []
    node_map = {}
    
    for node_data in graph_after:
        node_id = str(node_data['nodeId'])
        room_label = label_map.get(node_data.get('roomLabel', 0), 'A')
        
        node = {
            'id': node_id,
            'label': room_label,
            'nodeId': node_id  # Always include nodeId for display
        }
        
        # Add roomIndex if present (marks special nodes)
        if 'roomIndex' in node_data:
            node['roomIndex'] = node_data['roomIndex']
            # Special handling for START node
            if node_data['roomIndex'] == 0:
                node['id'] = 'START'
                node['nodeId'] = node_id
        
        nodes.append(node)
        node_map[node_id] = node
    
    # Build edges from doors arrays
    edges = []
    for node_data in graph_after:
        source_id = str(node_data['nodeId'])
        source_node = node_map.get(source_id)
        
        # Use START for roomIndex 0
        if source_node and source_node.get('id') == 'START':
            source_id = 'START'
        
        doors = node_data.get('doors', [])
        for door_num, target_node_id in enumerate(doors):
            if target_node_id is not None:
                target_id = str(target_node_id)
                target_node = node_map.get(target_id)
                
                # Use START for roomIndex 0
                if target_node and target_node.get('id') == 'START':
                    target_id = 'START'
                
                edges.append({
                    'source': source_id,
                    'target': target_id,
                    'door': door_num
                })
    
    # Create visualization state with both ping and search paths
    viz_state = {
        'timestamp': datetime.now().isoformat(),
        'iterationnumber': data.get('iterationnumber', 0),
        'current_querypath': clean_query if not is_ping else '',  # Regular query path
        'ping_path': clean_query if is_ping else '',  # Ping path (green)
        'search_path': clean_query if not is_ping else '',  # Search/exploration path (red)
        'isPingQuery': is_ping,
        'current_graph': {
            'nodes': nodes,
            'edges': edges
        }
    }
    
    # Include graphBefore info if present
    if 'graphBefore' in data:
        viz_state['graphBefore'] = data['graphBefore']
    
    return viz_state

def convert_exploration_format(exploration_data):
    """Convert exploration format to visualization format"""
    # Check if this is the new node format with graphAfter
    if 'graphAfter' in exploration_data:
        return convert_node_format(exploration_data)
    
    # Extract query without brackets
    query = exploration_data.get('query', '')
    clean_query = ''.join(c for c in query if c.isdigit())
    
    # Get result labels
    result = exploration_data.get('result', [])
    
    # Build graph from query and results
    nodes = [{'id': 'START', 'label': result[0] if result else 0}]
    edges = []
    node_map = {'START': nodes[0]}
    
    current_path = ''
    current_node_id = 'START'
    
    for i, door in enumerate(clean_query):
        current_path += door
        door_num = int(door)
        
        # Check if we already have an edge from current node with this door
        existing_edge = None
        for edge in edges:
            if edge['source'] == current_node_id and edge['door'] == door_num:
                existing_edge = edge
                current_node_id = edge['target']
                break
        
        if not existing_edge and i + 1 < len(result):
            # Create new node if needed
            new_node_id = current_path
            if new_node_id not in node_map:
                # Map numeric labels to A,B,C,D
                label_map = {0: 'A', 1: 'B', 2: 'C', 3: 'D'}
                label = label_map.get(result[i + 1], 'A')
                
                new_node = {'id': new_node_id, 'label': label}
                nodes.append(new_node)
                node_map[new_node_id] = new_node
            
            # Add edge
            edges.append({
                'source': current_node_id,
                'target': new_node_id,
                'door': door_num
            })
            current_node_id = new_node_id
    
    # Create visualization state
    return {
        'timestamp': datetime.now().isoformat(),
        'iterationnumber': exploration_data.get('iterationnumber', 0),
        'current_querypath': clean_query,
        'current_graph': {
            'nodes': nodes,
            'edges': edges
        }
    }

def read_jsonl_file(filepath, from_position=0):
    """Read JSONL file from a specific position"""
    states = []
    new_position = from_position
    
    try:
        with open(filepath, 'r') as f:
            # Seek to last position
            f.seek(from_position)
            
            line_num = 0
            for line in f:
                line = line.strip()
                if line:
                    try:
                        state = json.loads(line)
                        
                        # Check if this is exploration format or visualization format
                        if 'query' in state and 'result' in state:
                            # Convert exploration format to visualization format
                            state = convert_exploration_format(state)
                            state['iterationnumber'] = line_num
                        
                        states.append(state)
                        line_num += 1
                    except json.JSONDecodeError as e:
                        print(f"Error parsing line: {e}")
            
            # Remember where we stopped
            new_position = f.tell()
    
    except FileNotFoundError:
        print(f"File {filepath} not found")
    
    return states, new_position

def load_all_states(filepath='graph_states.jsonl'):
    """Load all states from JSONL file"""
    global graph_states, last_position, file_path, incremental_graph_state
    
    # Reset incremental graph state for new file
    incremental_graph_state = {'nodes': {}, 'edges': {}}
    
    file_path = filepath
    with states_lock:
        graph_states = []
        states, last_position = read_jsonl_file(filepath, 0)
        graph_states.extend(states)
    
    print(f"Loaded {len(graph_states)} states from {filepath}")
    return len(graph_states)

def check_for_new_states():
    """Check if new states have been added to the file"""
    global graph_states, last_position, file_path
    
    new_states, new_position = read_jsonl_file(file_path, last_position)
    
    if new_states:
        with states_lock:
            graph_states.extend(new_states)
            last_position = new_position
        print(f"Found {len(new_states)} new states")
    
    return new_states

def create_sample_data():
    """Create sample JSONL data for testing"""
    sample_states = [
        {
            "timestamp": "2024-01-01T12:00:00",
            "iterationnumber": 0,
            "current_querypath": "",
            "current_graph": {
                "nodes": [
                    {"id": "START", "label": "A"}
                ],
                "edges": []
            }
        },
        {
            "timestamp": "2024-01-01T12:00:01",
            "iterationnumber": 1,
            "current_querypath": "0",
            "current_graph": {
                "nodes": [
                    {"id": "START", "label": "A"},
                    {"id": "0", "label": "B"}
                ],
                "edges": [
                    {"source": "START", "target": "0", "door": 0}
                ]
            }
        },
        {
            "timestamp": "2024-01-01T12:00:02",
            "iterationnumber": 2,
            "current_querypath": "01",
            "current_graph": {
                "nodes": [
                    {"id": "START", "label": "A"},
                    {"id": "0", "label": "B"},
                    {"id": "1", "label": "C"}
                ],
                "edges": [
                    {"source": "START", "target": "0", "door": 0},
                    {"source": "START", "target": "1", "door": 1}
                ]
            }
        }
    ]
    
    # Write as JSONL
    with open('graph_states.jsonl', 'w') as f:
        for state in sample_states:
            f.write(json.dumps(state) + '\n')
    
    return sample_states

@app.route('/')
def index():
    """Serve the main visualization page"""
    return render_template('index.html')

@app.route('/api/states')
def get_states():
    """Get all current graph states"""
    with states_lock:
        return jsonify({
            'states': graph_states,
            'total': len(graph_states)
        })

@app.route('/api/state/<int:index>')
def get_state(index):
    """Get a specific graph state by index"""
    with states_lock:
        if 0 <= index < len(graph_states):
            return jsonify(graph_states[index])
        else:
            return jsonify({'error': 'Invalid state index'}), 404

@app.route('/api/check_updates')
def check_updates():
    """Check for new states (polling endpoint)"""
    new_states = check_for_new_states()
    return jsonify({
        'new_states': new_states,
        'total': len(graph_states)
    })

@app.route('/api/stream')
def stream_updates():
    """Server-Sent Events endpoint for live updates"""
    def generate():
        last_check = time.time()
        
        while True:
            # Check for new states every 0.5 seconds
            time.sleep(0.5)
            
            new_states = check_for_new_states()
            if new_states:
                for state in new_states:
                    # Send each new state as an SSE event
                    data = json.dumps({
                        'state': state,
                        'total': len(graph_states)
                    })
                    yield f"data: {data}\n\n"
            
            # Send heartbeat every 10 seconds to keep connection alive
            if time.time() - last_check > 10:
                yield f"data: {json.dumps({'heartbeat': True})}\n\n"
                last_check = time.time()
    
    return Response(generate(), mimetype='text/event-stream')

@app.route('/api/load_data', methods=['POST'])
def load_data():
    """Load data directly from uploaded content"""
    global graph_states, file_path, last_position
    
    data = request.json
    content = data.get('data', '')
    format_type = data.get('format', 'jsonl')
    
    try:
        graph_states = []
        line_num = 0
        
        if format_type == 'json':
            # Parse as JSON array
            states_list = json.loads(content)
            for state in states_list:
                # Check if conversion needed
                if 'query' in state and 'result' in state:
                    state = convert_exploration_format(state)
                    state['iterationnumber'] = line_num
                graph_states.append(state)
                line_num += 1
        else:
            # Parse as JSONL
            for line in content.strip().split('\n'):
                if line.strip():
                    try:
                        state = json.loads(line)
                        
                        # Check if this is exploration format
                        if 'query' in state and 'result' in state:
                            state = convert_exploration_format(state)
                            state['iterationnumber'] = line_num
                        
                        graph_states.append(state)
                        line_num += 1
                    except json.JSONDecodeError:
                        continue
        
        # Save to local file for live updates
        file_path = 'uploaded_states.jsonl'
        with open(file_path, 'w') as f:
            for state in graph_states:
                f.write(json.dumps(state) + '\n')
        
        last_position = os.path.getsize(file_path)
        
        return jsonify({
            'success': True,
            'states_loaded': len(graph_states),
            'message': f"Loaded {len(graph_states)} states"
        })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'states_loaded': 0,
            'message': f"Error parsing file: {str(e)}"
        })

@app.route('/api/load', methods=['POST'])
def load_file():
    """Load a new JSONL file"""
    data = request.json
    filepath = data.get('filepath', 'graph_states.jsonl')
    
    # Check if file exists
    if not os.path.exists(filepath):
        # Create sample file
        create_sample_data()
        filepath = 'graph_states.jsonl'
    
    count = load_all_states(filepath)
    
    return jsonify({
        'success': True,
        'states_loaded': count,
        'message': f"Loaded {count} states from {filepath}"
    })

@app.route('/api/append_state', methods=['POST'])
def append_state():
    """Append a new state to the file (for testing)"""
    global file_path
    
    state = request.json
    
    # Write to file
    with open(file_path, 'a') as f:
        f.write(json.dumps(state) + '\n')
    
    # The SSE stream will pick it up automatically
    return jsonify({'success': True})

def generate_next_exploration_path():
    """Generate the next logical path to explore"""
    global current_graph, explored_paths
    
    # If no nodes, start fresh
    if not current_graph['nodes']:
        return ""
    
    # Strategy: Explore systematically
    # 1. Single doors from START: 0, 1, 2, 3, 4, 5
    # 2. Two-door combinations: 00, 01, 02, ...
    # 3. Expand from discovered nodes
    
    # Try single doors first
    for door in range(6):
        path = str(door)
        if path not in explored_paths:
            return path
    
    # Try two-door combinations
    for door1 in range(6):
        for door2 in range(6):
            path = f"{door1}{door2}"
            if path not in explored_paths:
                return path
    
    # Try three-door combinations (limited set)
    for door1 in range(3):
        for door2 in range(3):
            for door3 in range(3):
                path = f"{door1}{door2}{door3}"
                if path not in explored_paths:
                    return path
    
    # Random exploration for variety
    path = ""
    for _ in range(random.randint(1, 5)):
        path += str(random.randint(0, 5))
    
    return path

def auto_generate_states():
    """Background thread that generates new states"""
    global file_path, current_graph, explored_paths, auto_generation_stop
    
    # Initialize if needed
    if not graph_states:
        # Start with initial state
        current_graph = {
            'nodes': [{'id': 'START', 'label': random.choice(['A', 'B', 'C', 'D'])}],
            'edges': []
        }
        initial_state = {
            'timestamp': datetime.now().isoformat(),
            'iterationnumber': 0,
            'current_querypath': '',
            'current_graph': current_graph.copy()
        }
        with open(file_path, 'a') as f:
            f.write(json.dumps(initial_state) + '\n')
    else:
        # Load current graph from last state
        with states_lock:
            if graph_states:
                last_state = graph_states[-1]
                current_graph = {
                    'nodes': [n.copy() for n in last_state['current_graph']['nodes']],
                    'edges': [e.copy() for e in last_state['current_graph']['edges']]
                }
                # Build explored paths from existing states
                explored_paths = {s['current_querypath'] for s in graph_states if s['current_querypath']}
    
    iteration = len(graph_states)
    
    while not auto_generation_stop.is_set():
        # Generate next exploration path
        new_path = generate_next_exploration_path()
        explored_paths.add(new_path)
        
        # Simulate discovering a new node or connection
        new_nodes = current_graph['nodes'].copy()
        new_edges = current_graph['edges'].copy()
        
        # Determine what we discover
        if new_path and random.random() > 0.3:  # 70% chance of discovery
            # Find or create target node
            if new_path:
                # Traverse the path to find where we end up
                current_node_id = 'START'
                path_so_far = ''
                
                for i, door in enumerate(new_path):
                    path_so_far += door
                    door_num = int(door)
                    
                    # Check if we already have this edge from current node
                    edge_found = False
                    for edge in new_edges:
                        if edge['source'] == current_node_id and edge['door'] == door_num:
                            current_node_id = edge['target']
                            edge_found = True
                            break
                    
                    if not edge_found:
                        # Determine the target node ID
                        # Could be a new node or cycle back to existing
                        if random.random() < 0.15 and len(new_nodes) > 5:  # 15% chance of cycle
                            # Create a cycle to an existing node
                            possible_targets = [n for n in new_nodes if n['id'] != current_node_id]
                            if possible_targets:
                                target_node = random.choice(possible_targets)
                                new_node_id = target_node['id']
                                node_exists = True
                            else:
                                # Create new node
                                new_node_id = path_so_far
                                node_exists = False
                        else:
                            # Create new node with path as ID
                            new_node_id = path_so_far
                            node_exists = any(n['id'] == new_node_id for n in new_nodes)
                        
                        # Add node if it doesn't exist
                        if not node_exists:
                            new_nodes.append({
                                'id': new_node_id,
                                'label': random.choice(['A', 'B', 'C', 'D'])
                            })
                        
                        # Add edge
                        new_edges.append({
                            'source': current_node_id,
                            'target': new_node_id,
                            'door': door_num
                        })
                        current_node_id = new_node_id
        
        # Create new state
        new_state = {
            'timestamp': datetime.now().isoformat(),
            'iterationnumber': iteration,
            'current_querypath': new_path,
            'current_graph': {
                'nodes': new_nodes,
                'edges': new_edges
            }
        }
        
        # Update current graph
        current_graph = {'nodes': new_nodes, 'edges': new_edges}
        
        # Append to file
        with open(file_path, 'a') as f:
            f.write(json.dumps(new_state) + '\n')
        
        iteration += 1
        
        # Wait 1 second before next generation
        auto_generation_stop.wait(1)

@app.route('/api/auto_generate', methods=['POST'])
def control_auto_generation():
    """Control auto-generation of states"""
    global auto_generation_thread, auto_generation_stop
    
    data = request.json
    action = data.get('action')
    
    if action == 'start':
        # Start auto-generation if not already running
        if auto_generation_thread is None or not auto_generation_thread.is_alive():
            auto_generation_stop.clear()
            auto_generation_thread = Thread(target=auto_generate_states)
            auto_generation_thread.daemon = True
            auto_generation_thread.start()
            return jsonify({'success': True, 'message': 'Auto-generation started'})
        else:
            return jsonify({'success': False, 'message': 'Auto-generation already running'})
    
    elif action == 'stop':
        # Stop auto-generation
        if auto_generation_thread and auto_generation_thread.is_alive():
            auto_generation_stop.set()
            auto_generation_thread.join(timeout=2)
            auto_generation_thread = None
            return jsonify({'success': True, 'message': 'Auto-generation stopped'})
        else:
            return jsonify({'success': False, 'message': 'Auto-generation not running'})
    
    return jsonify({'success': False, 'message': 'Invalid action'})

from datetime import datetime

if __name__ == '__main__':
    # Check if sample file exists, create if not
    if not os.path.exists('graph_states.jsonl'):
        print("Creating sample JSONL file...")
        create_sample_data()
    
    # Load initial data
    load_all_states()
    
    # Run the Flask app
    print("Starting visualization server on http://127.0.0.1:9898")
    print("Watching for updates to graph_states.jsonl")
    app.run(debug=True, host='127.0.0.1', port=9898)