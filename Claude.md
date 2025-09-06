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

## Development Notes

- The main entry point is in `Sources/ICFPWorkerCLI/Worker.swift`
- Workers implement the async `run()` method pattern
- Graph state is maintained using reference types for efficient updates
- Exploration results are processed incrementally to build the map