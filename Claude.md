# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ICFP Programming Contest 2025 - The Ædificium Explorer

This Swift solution maps hexagonal libraries for the ICFP 2025 contest. The goal is to deduce the complete structure of interconnected hexagonal rooms through minimal API exploration queries.

## Project Structure

### Core Components
- **ICFPWorkerLib**: Main library containing exploration logic
  - `Workers/`: Different exploration strategies (BasicWorker, DeBruijnWorker, FindEverythingWorker, GenerateEverythingWorker)
  - `VibeCoded/`: Core exploration pipeline components
    - `ExplorationOrchestrator`: Coordinates the entire exploration process
    - `GraphBuilder`: Maintains discovered graph structure
    - `GraphEvaluator`: Assesses graph completeness
    - `PathGenerator`: Creates exploration path sequences
    - `NextStepPredictor`: Generates targeted exploration paths
    - `ExplorationClient`: Abstract API communication protocol
- **ICFPWorkerCLI**: Command-line interface for running workers

### Room Navigation System
- Hexagonal rooms with 6 doors (labeled 0-5)
- Each room has a 2-bit label (values: 0, 1, 2, or 3)
- Doors may connect to different rooms or loop back
- Routes are sequences of door numbers (e.g., "0325")

## Essential Commands

### Build & Run
```bash
# Build the project
swift build

# Run a worker (pass worker name as argument)
swift run icfpworker BasicWorker
swift run icfpworker DeBruijnWorker  
swift run icfpworker FindEverything

# Run all tests
swift test

# Run specific test suite
swift test --filter GraphBuilderTests
swift test --filter ExplorationOrchestratorTests
swift test --filter PathGeneratorTests
swift test --filter GraphEvaluatorTests
swift test --filter NextStepPredictorTests
```

## Configuration

The project uses a `.env` file for API configuration:
- `teamId`: Contest team identifier
- `apiUrl`: API endpoint URL

The `EnvConfig` class loads these settings automatically from `.env` or from the `ICFP_CONFIG_PATH` environment variable.

## API Integration

### Key Models (APIModels.swift)
- `ExploreRequest/Response`: Submit exploration paths and receive room labels
- `GuessRequest/Response`: Submit final map solution
- `MapDescription`: Room connections representation
- `Connection`: Door-to-door mappings between rooms

### HTTPTaskClient
Handles actual HTTP communication with the contest API. Supports both mock and real exploration clients for testing.

## Worker Strategies

1. **BasicWorker**: Simple exploration strategy
2. **DeBruijnWorker**: Uses De Bruijn sequences for systematic exploration
3. **FindEverythingWorker**: Exhaustive exploration approach (currently active)
4. **GenerateEverythingWorker**: Generates complete map predictions

Workers can be run against:
- `MockExplorationClient`: For local testing with predefined layouts
- `HTTPExplorationClient`: For actual API interaction

## Problem Definitions

Predefined problem instances (Problems.swift):
- `probatio`: 3 rooms (testing)
- `primus`: 6 rooms
- `secundus`: 12 rooms
- `tertius`: 18 rooms
- `quartus`: 24 rooms
- `quintus`: 30 rooms

## Testing Infrastructure

The project includes comprehensive tests with a `MockExplorationClient` that simulates various library layouts:
- `.hexagon`: Simple hexagonal structure
- `.threeRooms`: Basic 3-room layout
- Custom layouts can be defined for testing

## Key Architectural Patterns

1. **Protocol-Based Design**: `ExplorationClient` protocol enables easy mocking and testing
2. **Pipeline Architecture**: Clear separation between exploration, evaluation, and prediction phases
3. **Information Gain Scoring**: Paths rated by expected discovery value
4. **Confidence-Based Termination**: Stops exploration when graph is sufficiently complete

## CRITICAL: Room Identification Strategy via Path Signatures

### Core Principle: NO SELF-LOOP ASSUMPTIONS
**IMPORTANT**: Never assume self-loops exist. If you explore a door and observe the same label, it could be:
- A self-loop (door leads back to the same room)
- A different room that happens to have the same label

We can ONLY trust connections to rooms with DIFFERENT labels as definitive information.

### Path-Based Signatures for Room Identification

Rooms are uniquely identified by their **path expansion patterns**. A signature is a collection of path→label mappings:

Example signature: `{"0":A, "5":B, "50":A, "55":C}`

This means:
- Door 0 leads to a room with label A
- Door 5 leads to a room with label B
- Path "50" (door 5 then door 0) leads to label A
- Path "55" (door 5 then door 5) leads to label C

### Base-6 Hamming-like Exploration Strategy

Since each room has 6 doors (0-5), we use base-6 patterns for systematic exploration:

**Level 1 (6 paths):** `"0", "1", "2", "3", "4", "5"`

**Level 2 (strategic selection from 36 possible):**
- Identity patterns: `"00", "11", "22", "33", "44", "55"`
- Adjacent pairs: `"01", "12", "23", "34", "45", "50"`
- Skip patterns: `"02", "13", "24", "35", "40", "51"`

**Level 3 (if needed for complex graphs):**
- Extend patterns to 3 digits for deeper exploration

### Signature Optimization

Not all paths provide useful information:
1. **Remove redundant paths**: If all rooms show "55":C, this doesn't distinguish them
2. **Keep only distinguishing features**: Paths that yield different labels for different rooms
3. **Minimal sufficient set**: The smallest signature that still uniquely identifies each room

Example optimization:
- Before: `{"0":A, "5":B, "00":A, "05":B, "50":A, "55":C}` (all rooms have "55":C)
- After: `{"0":A, "5":B, "50":A}` (minimal but unique)

### Duplicate Room Detection

Two nodes represent the same room if and only if they have **identical path signatures** when fully expanded:
1. Expand each node to depth 2-3
2. Build complete path→label mappings
3. Compare signatures
4. Nodes with identical signatures are the same room

This approach treats the problem like finding graph isomorphisms at the local level, using path patterns as the distinguishing features.

### Smart Hybrid Exploration Strategy

**IMPORTANT**: Door numbers 0-5 are just arbitrary labels with no geometric meaning. There are no "opposite" or "adjacent" doors - just 6 different doors.

The most efficient approach uses a hybrid strategy to minimize API calls:

#### Phase 1: Strategic Initial Exploration
Perform a carefully selected set of explorations to maximize pattern discovery:
- All single doors: "0", "1", "2", "3", "4", "5"
- Sample of depth-2 patterns: "00", "01", "11", "22", "05", "50"
- These provide a good initial "sketch" of the graph structure

#### Phase 2: Compute Partial Signatures
- Build signatures from Phase 1 exploration data
- Group nodes by similar patterns
- Identify which groups need disambiguation

#### Phase 3: Targeted Disambiguation
Based on partial signatures, intelligently choose paths to distinguish ambiguous nodes:
- If two nodes have identical partial signatures, explore paths likely to reveal differences
- Focus exploration on ambiguous groups rather than fully explored nodes
- Use information gain to prioritize paths

#### Phase 4: Verification
Once the number of unique signatures matches expected room count:
- Perform minimal verification queries
- Confirm groupings are correct

This approach balances thoroughness with efficiency, using early exploration results to guide later queries. It's significantly faster than exhaustive exploration while ensuring all unique rooms are discovered.

## Development Notes

- The main entry point is in `Sources/ICFPWorkerCLI/Worker.swift`
- Workers implement the async `run()` method pattern
- Graph state is maintained using reference types for efficient updates
- Exploration results are processed incrementally to build the map