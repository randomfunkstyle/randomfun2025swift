#!/usr/bin/env python3
"""
Generate sample JSONL data for testing the graph visualization.
Creates a progressively expanding graph exploration dataset.
"""
import json
import random
from datetime import datetime, timedelta

def generate_hexagon_exploration():
    """Generate a sample hexagon graph exploration sequence"""
    states = []
    base_time = datetime.now()
    
    # Initial state - just the starting room
    states.append({
        "timestamp": base_time.isoformat(),
        "iterationnumber": 0,
        "current_querypath": "",
        "current_graph": {
            "nodes": [
                {"id": "START", "label": "A"}
            ],
            "edges": []
        }
    })
    
    # Explore door 0
    states.append({
        "timestamp": (base_time + timedelta(seconds=1)).isoformat(),
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
    })
    
    # Explore door 1
    states.append({
        "timestamp": (base_time + timedelta(seconds=2)).isoformat(),
        "iterationnumber": 2,
        "current_querypath": "1",
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
    })
    
    # Explore door 2
    states.append({
        "timestamp": (base_time + timedelta(seconds=3)).isoformat(),
        "iterationnumber": 3,
        "current_querypath": "2",
        "current_graph": {
            "nodes": [
                {"id": "START", "label": "A"},
                {"id": "0", "label": "B"},
                {"id": "1", "label": "C"},
                {"id": "2", "label": "D"}
            ],
            "edges": [
                {"source": "START", "target": "0", "door": 0},
                {"source": "START", "target": "1", "door": 1},
                {"source": "START", "target": "2", "door": 2}
            ]
        }
    })
    
    # Explore door 3 (loops back to START)
    states.append({
        "timestamp": (base_time + timedelta(seconds=4)).isoformat(),
        "iterationnumber": 4,
        "current_querypath": "3",
        "current_graph": {
            "nodes": [
                {"id": "START", "label": "A"},
                {"id": "0", "label": "B"},
                {"id": "1", "label": "C"},
                {"id": "2", "label": "D"},
                {"id": "3", "label": "A"}
            ],
            "edges": [
                {"source": "START", "target": "0", "door": 0},
                {"source": "START", "target": "1", "door": 1},
                {"source": "START", "target": "2", "door": 2},
                {"source": "START", "target": "3", "door": 3}
            ]
        }
    })
    
    # Explore door 4
    states.append({
        "timestamp": (base_time + timedelta(seconds=5)).isoformat(),
        "iterationnumber": 5,
        "current_querypath": "4",
        "current_graph": {
            "nodes": [
                {"id": "START", "label": "A"},
                {"id": "0", "label": "B"},
                {"id": "1", "label": "C"},
                {"id": "2", "label": "D"},
                {"id": "3", "label": "A"},
                {"id": "4", "label": "B"}
            ],
            "edges": [
                {"source": "START", "target": "0", "door": 0},
                {"source": "START", "target": "1", "door": 1},
                {"source": "START", "target": "2", "door": 2},
                {"source": "START", "target": "3", "door": 3},
                {"source": "START", "target": "4", "door": 4}
            ]
        }
    })
    
    # Explore door 5
    states.append({
        "timestamp": (base_time + timedelta(seconds=6)).isoformat(),
        "iterationnumber": 6,
        "current_querypath": "5",
        "current_graph": {
            "nodes": [
                {"id": "START", "label": "A"},
                {"id": "0", "label": "B"},
                {"id": "1", "label": "C"},
                {"id": "2", "label": "D"},
                {"id": "3", "label": "A"},
                {"id": "4", "label": "B"},
                {"id": "5", "label": "A"}
            ],
            "edges": [
                {"source": "START", "target": "0", "door": 0},
                {"source": "START", "target": "1", "door": 1},
                {"source": "START", "target": "2", "door": 2},
                {"source": "START", "target": "3", "door": 3},
                {"source": "START", "target": "4", "door": 4},
                {"source": "START", "target": "5", "door": 5}
            ]
        }
    })
    
    # Now explore from room 0 (door 0 from B)
    states.append({
        "timestamp": (base_time + timedelta(seconds=7)).isoformat(),
        "iterationnumber": 7,
        "current_querypath": "00",
        "current_graph": {
            "nodes": [
                {"id": "START", "label": "A"},
                {"id": "0", "label": "B"},
                {"id": "1", "label": "C"},
                {"id": "2", "label": "D"},
                {"id": "3", "label": "A"},
                {"id": "4", "label": "B"},
                {"id": "5", "label": "A"},
                {"id": "00", "label": "C"}
            ],
            "edges": [
                {"source": "START", "target": "0", "door": 0},
                {"source": "START", "target": "1", "door": 1},
                {"source": "START", "target": "2", "door": 2},
                {"source": "START", "target": "3", "door": 3},
                {"source": "START", "target": "4", "door": 4},
                {"source": "START", "target": "5", "door": 5},
                {"source": "0", "target": "00", "door": 0}
            ]
        }
    })
    
    # Continue exploring...
    states.append({
        "timestamp": (base_time + timedelta(seconds=8)).isoformat(),
        "iterationnumber": 8,
        "current_querypath": "01",
        "current_graph": {
            "nodes": [
                {"id": "START", "label": "A"},
                {"id": "0", "label": "B"},
                {"id": "1", "label": "C"},
                {"id": "2", "label": "D"},
                {"id": "3", "label": "A"},
                {"id": "4", "label": "B"},
                {"id": "5", "label": "A"},
                {"id": "00", "label": "C"},
                {"id": "01", "label": "D"}
            ],
            "edges": [
                {"source": "START", "target": "0", "door": 0},
                {"source": "START", "target": "1", "door": 1},
                {"source": "START", "target": "2", "door": 2},
                {"source": "START", "target": "3", "door": 3},
                {"source": "START", "target": "4", "door": 4},
                {"source": "START", "target": "5", "door": 5},
                {"source": "0", "target": "00", "door": 0},
                {"source": "0", "target": "01", "door": 1}
            ]
        }
    })
    
    return states

def generate_sample_jsonl(output_file='graph_states.jsonl', num_states=50):
    """Generate sample JSONL data with progressively expanding graph"""
    
    # Room labels for variety
    labels = ['A', 'B', 'C', 'D']
    
    # Track nodes and edges as we build
    nodes = [{"id": "START", "label": random.choice(labels)}]
    edges = []
    
    # Build states progressively
    states = []
    timestamp = datetime.now()
    current_path = ""
    
    for i in range(num_states):
        # Add a new node every few iterations
        if i > 0 and i % 3 == 0:
            node_id = str(len(nodes) - 1)
            new_label = random.choice(labels)
            nodes.append({"id": node_id, "label": new_label})
            
            # Connect to existing nodes
            if len(nodes) > 2:
                # Connect from a random existing node
                source_node = random.choice(nodes[:-1])
                door = random.randint(0, 5)
                edges.append({
                    "source": source_node["id"],
                    "target": node_id,
                    "door": door
                })
                
                # Maybe add a second connection
                if random.random() > 0.5 and len(nodes) > 3:
                    source_node = random.choice(nodes[:-1])
                    door = random.randint(0, 5)
                    edges.append({
                        "source": source_node["id"],
                        "target": node_id,
                        "door": door
                    })
        
        # Update query path
        if i > 0:
            current_path += str(random.randint(0, 5))
            # Keep path reasonable length
            if len(current_path) > 10:
                current_path = current_path[-10:]
        
        # Create state
        state = {
            "timestamp": timestamp.isoformat(),
            "iterationnumber": i,
            "current_querypath": current_path,
            "current_graph": {
                "nodes": nodes.copy(),
                "edges": edges.copy()
            }
        }
        
        states.append(state)
        timestamp += timedelta(seconds=1)
    
    # Write as JSONL
    with open(output_file, 'w') as f:
        for state in states:
            f.write(json.dumps(state) + '\n')
    
    print(f"Generated {num_states} states in {output_file}")
    return num_states

def append_live_state(filepath='graph_states.jsonl'):
    """Append a new state to simulate live updates"""
    
    # Read existing states to get context
    states = []
    try:
        with open(filepath, 'r') as f:
            for line in f:
                states.append(json.loads(line.strip()))
    except FileNotFoundError:
        print(f"File {filepath} not found, creating new one")
        generate_sample_jsonl(filepath, 10)
        return
    
    if not states:
        print("No existing states found")
        return
    
    # Get last state
    last_state = states[-1]
    last_graph = last_state['current_graph']
    
    # Create new state with minor changes
    new_nodes = last_graph['nodes'].copy()
    new_edges = last_graph['edges'].copy()
    
    # Add a new node
    new_id = str(len(new_nodes))
    new_nodes.append({
        "id": new_id,
        "label": random.choice(['A', 'B', 'C', 'D'])
    })
    
    # Connect it
    if len(new_nodes) > 1:
        source = random.choice(new_nodes[:-1])
        new_edges.append({
            "source": source["id"],
            "target": new_id,
            "door": random.randint(0, 5)
        })
    
    # Create new state
    new_state = {
        "timestamp": datetime.now().isoformat(),
        "iterationnumber": last_state['iterationnumber'] + 1,
        "current_querypath": last_state['current_querypath'] + str(random.randint(0, 5)),
        "current_graph": {
            "nodes": new_nodes,
            "edges": new_edges
        }
    }
    
    # Append to file
    with open(filepath, 'a') as f:
        f.write(json.dumps(new_state) + '\n')
    
    print(f"Appended new state #{new_state['iterationnumber']} to {filepath}")

def generate_hexagon_jsonl(output_file='hexagon_states.jsonl'):
    """Generate hexagon exploration as JSONL"""
    states = generate_hexagon_exploration()
    
    # Write as JSONL
    with open(output_file, 'w') as f:
        for state in states:
            f.write(json.dumps(state) + '\n')
    
    print(f"Generated {len(states)} hexagon states in {output_file}")
    return len(states)

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        if sys.argv[1] == 'hexagon':
            generate_hexagon_jsonl()
        elif sys.argv[1] == 'append':
            append_live_state()
        elif sys.argv[1] == 'json':
            # Legacy JSON format
            states = generate_hexagon_exploration()
            with open("graph_states.json", "w") as f:
                json.dump(states, f, indent=2)
            print(f"Generated {len(states)} states in graph_states.json")
        else:
            num = int(sys.argv[1])
            generate_sample_jsonl(num_states=num)
    else:
        # Generate default JSONL sample
        generate_sample_jsonl()
        print("\nUsage:")
        print("  python generate_sample_data.py [number]  # Generate N states in JSONL")
        print("  python generate_sample_data.py hexagon   # Generate hexagon layout in JSONL")
        print("  python generate_sample_data.py append    # Append a live state")
        print("  python generate_sample_data.py json      # Generate legacy JSON format")