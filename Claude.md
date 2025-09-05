# ICFP Programming Contest 2025 - The Ædificium Task

## Task Overview
Contestants must map a complex library (the Ædificium) with hexagonal rooms. The goal is to construct an accurate map using minimal exploratory expeditions.

## Library Structure
- Rooms are **hexagonal** in shape
- Each room has **6 doors** (labeled 0-5), one on each side of the hexagon
- Each room has a 2-bit label (00, 01, 10, or 11) that can be observed when visited
- Rooms are arranged in a complex interconnected pattern
- Teams develop route plans to systematically explore and map the library

## Room Navigation Details

### Door System
- Each hexagonal room has 6 doors numbered **0 through 5**
- Doors correspond to the six sides of the hexagon
- When you go through a door, you may:
  - Enter a different room
  - Return to the same room (self-loop)
  - The passage may connect through different door numbers

### Movement Mechanics
- **Route plans** are sequences of door numbers (e.g., "0325")
- All expeditions start from the same initial room
- As you move through doors, you record the 2-bit label of each room visited
- The sequence of labels observed helps deduce the library's structure

### Example Navigation
- Route "0325" means:
  1. Start in initial room, go through door 0
  2. From new room, go through door 3
  3. From that room, go through door 2
  4. From that room, go through door 5
- For each room visited, you observe its 2-bit label

## API Endpoints

### Registration
- `POST /register` - Get a team ID
- `POST /select` - Choose a problem to solve
- `POST /explore` - Submit route plans and receive room label data
- `POST /guess` - Submit a candidate map

## Exploration Strategy
- Route plans are sequences of door numbers (0-5)
- **Maximum path length: 18 * number_of_rooms** (e.g., for 3 rooms, max path length is 54)
- **IMPORTANT: Cannot use batch exploration** - Each exploration must be a single path
- Each expedition records 2-bit room labels encountered
- The challenge is to deduce the complete map structure from partial observations
- Objective: minimize the number of expeditions needed to map the library
- **Approach: Use entropy-optimal paths** that maximize information gain about structure (e.g., "001122334455" pattern tests bidirectional connections)

## Scoring System
- Teams are ranked by expedition efficiency (fewer is better)
- Global leaderboard uses Borda count scoring method
- Rewards teams that can map libraries with the fewest queries

## Submission Requirements
- Submit code via Google form
- Include team ID and code repository URL
- Submission deadline: 3 hours after contest end

## Contest URL
https://icfpcontest2025.github.io/specs/task_from_tex.html

## Narrative Context
The task is presented as a medieval adventure where scholars Adso and William explore a mysterious monastic library called the Ædificium. William can understand the room labels but his failing eyesight limits him to reading only the first two bits, adding a storytelling layer to the technical challenge.