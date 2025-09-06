# DEVELOPMENT.md - 10x Implementation Plan

## Core Development Principles

### Single Responsibility
Each method does ONE thing well. No method should both explore AND compute signatures.

### Pure Functions
Given the same input, always produce the same output. No hidden state or side effects.

### Test First
Write test expectations before implementation. Each method has 5+ tests covering normal, edge, and error cases.

### Immutable Data
Return new structures instead of modifying existing ones. This makes debugging easier and prevents race conditions.

### Clear Contracts
Explicit input/output types. No ambiguous parameters or return values.

## Implementation Layers

## 1. Path Generation Layer

### `generatePaths(depth: Int) -> [String]`
**Responsibility**: Generate base-6 paths for given depth

**Contract**:
```swift
Input: depth (0-3)
Output: Array of path strings
Example: depth=1 returns ["0","1","2","3","4","5"]
```

**Tests**:
- `testGeneratesAllSingleDigitPaths()` - Verify all 6 paths for depth=1
- `testGeneratesCorrectDepth2Count()` - Should be strategic subset, not all 36
- `testGeneratesNoEmptyPaths()` - No empty strings in output
- `testPathsAreUnique()` - No duplicate paths
- `testDepth0ReturnsEmptyArray()` - Edge case
- `testNegativeDepthThrows()` - Error handling

### `selectStrategicPaths(allPaths: [String], strategy: Strategy) -> [String]`
**Responsibility**: Filter paths based on strategy

**Contract**:
```swift
enum Strategy {
    case hammingLike  // Select ~30% using base-6 patterns
    case exhaustive   // Return all paths
    case minimal      // Return smallest distinguishing set
}
```

**Tests**:
- `testHammingStrategySelectsCorrectSubset()`
- `testExhaustiveStrategyReturnsAll()`
- `testMinimalStrategyReturnsSmallestSet()`
- `testEmptyInputReturnsEmpty()`
- `testInvalidStrategyUsesDefault()`

## 2. Exploration Layer

### `explorePathsFromNode(node: Node, paths: [String], sourceGraph: Graph) -> [PathResult]`
**Responsibility**: Execute exploration from a single node

**Contract**:
```swift
struct PathResult {
    let startNodeId: Int
    let path: String
    let observedLabels: [RoomLabel]
}
```

**Tests**:
- `testExploreSinglePathFromNode()`
- `testExploreMultiplePathsFromNode()`
- `testExploreEmptyPathReturnsStartLabel()`
- `testExploreInvalidPathReturnsEmpty()`
- `testExploreFromNonExistentNodeThrows()`
- `testExplorePerformance()` - Should be O(path.length)

### `batchExplore(explorations: [(NodeId, [String])], sourceGraph: Graph) -> [PathResult]`
**Responsibility**: Execute multiple explorations efficiently

**Tests**:
- `testBatchExploreMultipleNodes()`
- `testBatchExploreEmptyReturnsEmpty()`
- `testBatchExploreMaintainsOrder()`
- `testBatchExplorePerformance()` - Should be faster than individual
- `testBatchExploreHandlesErrors()` - Partial failures don't break all

## 3. Graph Building Layer

### `createNodeFromExploration(pathResult: PathResult, currentGraph: Graph) -> Graph`
**Responsibility**: Add single exploration result to graph

**Tests**:
- `testCreatesNewNodeForUnexploredPath()`
- `testReusesExistingNodeForExploredPath()`
- `testUpdatesNodeLabels()`
- `testPreservesExistingConnections()`
- `testHandlesEmptyPathResult()`
- `testImmutability()` - Original graph unchanged

### `mergeExplorationResults(results: [PathResult], graph: Graph) -> Graph`
**Responsibility**: Merge multiple exploration results

**Tests**:
- `testMergesMultipleResults()`
- `testHandlesDuplicatePaths()`
- `testPreservesNodeIdentities()`
- `testMergeEmptyResultsReturnsOriginal()`
- `testMergePerformance()` - Should be O(n)
- `testMergeOrderIndependent()` - Same results regardless of order

## 4. Label Analysis Layer

### `groupNodesByLabel(nodes: [Node]) -> [RoomLabel: [NodeId]]`
**Responsibility**: Group nodes by their observed label

**Tests**:
- `testGroupsNodesByLabel()`
- `testHandlesNodesWithoutLabels()`
- `testEmptyNodesReturnsEmptyGroups()`
- `testAllSameLabelSingleGroup()`
- `testAllDifferentLabelsMultipleGroups()`
- `testPerformanceLinearInNodes()`

### `prioritizeLabelGroups(groups: [RoomLabel: [NodeId]]) -> [PriorityGroup]`
**Responsibility**: Order groups by exploration priority

**Contract**:
```swift
struct PriorityGroup {
    let priority: Int  // 1 = highest (multiple nodes, same label)
    let label: RoomLabel
    let nodeIds: [NodeId]
    let reason: String  // Why this priority
}
```

**Tests**:
- `testMultiNodeGroupsGetHighPriority()`
- `testSingleNodeGroupsGetLowPriority()`
- `testEmptyGroupsExcluded()`
- `testStableSortWithinPriority()`
- `testPriorityOrder()` - Verify 1 > 2 > 3
- `testPriorityReasoning()` - Verify reason strings

## 5. Signature Computation Layer

### `computeNodeSignature(node: Node, paths: [String], graph: Graph) -> NodeSignature`
**Responsibility**: Compute signature for single node

**Contract**:
```swift
struct NodeSignature {
    let nodeId: NodeId
    let pathLabels: [String: RoomLabel]  // "01" -> B
    let exploredPaths: Set<String>       // Which paths we checked
    let isComplete: Bool                 // All requested paths explored
}
```

**Tests**:
- `testComputesSignatureForFullyExploredNode()`
- `testComputesPartialSignature()`
- `testEmptyPathsEmptySignature()`
- `testSignatureConsistency()` - Same input = same output
- `testHandlesNonExistentPaths()`
- `testSignatureCompleteness()` - Correctly marks complete/incomplete

### `computeAllSignatures(graph: Graph, standardPaths: [String]) -> [NodeSignature]`
**Responsibility**: Compute signatures for all nodes

**Tests**:
- `testComputesSignaturesForAllNodes()`
- `testUsesOnlyProvidedPaths()`
- `testEmptyGraphEmptySignatures()`
- `testSignatureCompleteness()`
- `testPerformanceLinearInNodes()`
- `testHandlesLargeGraphs()` - 1000+ nodes

## 6. Signature Comparison Layer

### `hashSignature(signature: NodeSignature) -> String`
**Responsibility**: Create comparable hash from signature

**Algorithm**: Sort paths alphabetically, concatenate path:label pairs

**Tests**:
- `testIdenticalSignaturesSameHash()`
- `testDifferentSignaturesDifferentHash()`
- `testHashDeterministic()`
- `testHashHandlesEmptySignature()`
- `testHashPerformance()` - Should be O(paths)
- `testHashCollisionRate()` - Should be near zero

### `findIdenticalSignatures(signatures: [NodeSignature]) -> [[NodeId]]`
**Responsibility**: Group nodes with identical signatures

**Tests**:
- `testGroupsIdenticalSignatures()`
- `testSeparatesDifferentSignatures()`
- `testHandlesEmptySignatures()`
- `testSingleNodeGroups()`
- `testAllIdenticalSingleGroup()`
- `testPerformanceNLogN()` - Due to sorting

## 7. Room Identification Layer

### `identifyUniqueRooms(signatureGroups: [[NodeId]]) -> RoomIdentification`
**Responsibility**: Assign room IDs to signature groups

**Contract**:
```swift
struct RoomIdentification {
    let rooms: [RoomId: [NodeId]]     // Room -> nodes in that room
    let nodeToRoom: [NodeId: RoomId]  // Node -> its room
    let roomSignatures: [RoomId: String] // Room -> its signature hash
}
```

**Tests**:
- `testAssignsUniqueRoomIds()`
- `testMapsAllNodesToRooms()`
- `testDeterministicRoomAssignment()`
- `testEmptyGroupsNoRooms()`
- `testRoomIdStartsAtZero()`
- `testBidirectionalMapping()` - rooms and nodeToRoom are consistent

### `validateRoomCount(rooms: [RoomId: [NodeId]], expected: Int) -> ValidationResult`
**Responsibility**: Check if we found the right number of rooms

**Contract**:
```swift
enum ValidationResult {
    case success
    case needsMoreExploration(found: Int, expected: Int)
    case tooManyRooms(found: Int, expected: Int)  // Indicates error
    case error(String)
}
```

**Tests**:
- `testValidatesCorrectCount()`
- `testDetectsInsufficientRooms()`
- `testDetectsTooManyRooms()`
- `testHandlesZeroExpected()`
- `testValidationMessage()` - Helpful error messages

## 8. Orchestration Layer ✅

### `shouldContinueExploration(state: ExplorationState) -> Decision` ✅
**Responsibility**: Decide whether to continue exploring

**Contract**:
```swift
struct ExplorationState {
    let uniqueRooms: Int
    let expectedRooms: Int
    let explorationDepth: Int
    let queryCount: Int
    let maxQueries: Int
    let maxDepth: Int
}

enum Decision {
    case continue(reason: String)
    case stop(reason: String)
    case error(String)
}
```

**Tests**:
- `testContinuesWhenInsufficientRooms()`
- `testStopsWhenEnoughRooms()`
- `testStopsAtMaxDepth()`
- `testStopsAtQueryLimit()`
- `testProvidesReasons()`
- `testHandlesInvalidState()`

### `selectNextExplorations(state: ExplorationState, graph: Graph, labelGroups: [PriorityGroup]) -> [String]` ✅
**Responsibility**: Choose what paths to explore next from starting node

**Strategy**: 
1. High priority groups first
2. Increase depth if no progress
3. Avoid redundant explorations

**Tests**:
- `testSelectsHighPriorityGroups()`
- `testExpandsExplorationDepth()`
- `testAvoidsRedundantExploration()`
- `testReturnsEmptyWhenComplete()`
- `testPerformanceWithLargeGraph()`
- `testBalancesExplorationAcrossGroups()`

## 9. Main Algorithm

### `identifyRooms(sourceGraph: Graph, expectedCount: Int, config: Config) -> Result`
**Responsibility**: Main entry point orchestrating all steps

**Contract**:
```swift
struct Config {
    let maxQueries: Int = 100
    let maxDepth: Int = 3
    let strategy: Strategy = .hammingLike
    let verbose: Bool = false
}

struct Result {
    let rooms: [RoomId: [NodeId]]
    let queryCount: Int
    let explorationDepth: Int
    let confidence: Float  // 0.0 to 1.0
    let executionTime: TimeInterval
}
```

**Tests**:
- `testIdentifiesThreeRooms()`
- `testIdentifiesSixRooms()`
- `testHandlesSingleRoom()`
- `testHandlesMaxRooms()`
- `testRespectsQueryLimit()`
- `testRespectsDepthLimit()`
- `testPerformanceScaling()`
- `testDeterministicResults()`
- `testConfigurationOptions()`

## Integration Tests

### Room Identification Integration
```swift
class RoomIdentificationIntegrationTests {
    func testEndToEndThreeRooms()
    func testEndToEndSixRooms()
    func testEndToEndTwelveRooms()
    func testMinimalQueries() // Verify optimization works
    func testDeterministicResults() // Same input = same output
    func testHandlesComplexGraphs()
    func testHandlesAmbiguousGraphs() // Many same labels
    func testProgressiveRefinement() // Each iteration improves
}
```

### Phase 1-5 Integration Tests (Expanded)

#### Three-Room Layout Integration (`ThreeRoomIntegrationTests.swift`)
```swift
class ThreeRoomIntegrationTests {
    // Complete algorithm flow for 3-room problem
    func testThreeRoomCompleteIdentification()
    func testThreeRoomInitialExpansion() // Verify 6 doors explored
    func testThreeRoomLabelAnalysis() // Verify groups: A=[6 nodes], B=[1 node]
    func testThreeRoomSignatureComputation() // Verify duplicates detected
    func testThreeRoomPathGeneration() // Verify strategic paths selected
    func testThreeRoomExplorationExecution() // Verify batch exploration
    func testThreeRoomGraphBuilding() // Verify graph structure
    func testThreeRoomDuplicateMerging() // Verify nodes 1-5 are same as start
    func testThreeRoomPerformance() // Should complete in <20 queries
    func testThreeRoomMinimalExploration() // Find optimal path set
}
```

#### Six-Room Hexagon Integration (`SixRoomIntegrationTests.swift`)
```swift
class SixRoomIntegrationTests {
    // Complete algorithm flow for 6-room hexagon
    func testSixRoomCompleteIdentification()
    func testSixRoomInitialExpansion() // Verify 6 doors explored
    func testSixRoomLabelAnalysis() // Verify duplicate labels detected
    func testSixRoomDeepExploration() // Verify depth-2 paths used
    func testSixRoomSignatureComputation() // Verify 6 unique signatures
    func testSixRoomDuplicateResolution() // Rooms 0&4 have label 0, but different signatures
    func testSixRoomPathOptimization() // Remove redundant paths
    func testSixRoomGraphConstruction() // Verify hexagon structure
    func testSixRoomPerformance() // Should complete in <50 queries
    func testSixRoomConnectionVerification() // Verify all connections correct
}
```

#### Algorithm Flow Integration (`AlgorithmFlowTests.swift`)
```swift
class AlgorithmFlowTests {
    // Test complete flow of phases 1-5
    func testPhase1InitialExpansion() // Graph has 6+ nodes after first expansion
    func testPhase2LabelDistribution() // Correct grouping and prioritization
    func testPhase3PathGeneration() // Strategic paths are selected
    func testPhase4ExplorationExecution() // Batch exploration works
    func testPhase5GraphBuilding() // Graph grows with each exploration
    func testSignatureSystemFlow() // Signatures correctly identify rooms
    func testDuplicateMergingFlow() // Nodes with identical signatures merged
    func testIncrementalRefinement() // Each iteration improves accuracy
    func testConvergenceDetection() // Algorithm knows when to stop
    func testBacktrackingCapability() // Can recover from wrong assumptions
}
```

#### Signature System Integration (`SignatureSystemIntegrationTests.swift`)
```swift
class SignatureSystemIntegrationTests {
    // End-to-end signature system validation
    func testDuplicateDetection() // Nodes with same signature identified
    func testUniqueRoomIdentification() // Each signature = one room
    func testPathOptimization() // Redundant paths removed
    func testMinimalSignatures() // Smallest distinguishing set found
    func testSignatureEvolution() // Signatures refined with more exploration
    func testPartialSignatureMatching() // Early duplicate detection
    func testSignatureConsistency() // Same exploration = same signature
    func testSignatureMerging() // Combine partial signatures correctly
    func testSignatureInvalidation() // Handle contradictory data
    func testSignatureCompleteness() // Know when signatures are sufficient
}
```

#### Edge Case Integration (`EdgeCaseIntegrationTests.swift`)
```swift
class EdgeCaseIntegrationTests {
    // Challenging scenarios
    func testAllSameLabel() // All rooms have label A
    func testMaximumDuplicates() // 8 rooms, 4 labels (pigeonhole)
    func testDeepPathsRequired() // Need depth-3 to distinguish
    func testPartialInformation() // Incomplete exploration data
    func testDisconnectedComponents() // Multiple isolated subgraphs
    func testSelfLoopHeavy() // Most doors are self-loops
    func testFullyConnected() // Every room connects to every other
    func testAsymmetricConnections() // One-way doors only
    func testLabelChanges() // Labels change during exploration
    func testMaximalComplexity() // Worst-case scenario
}
```

## Performance Tests

### Efficiency Validation
```swift
class RoomIdentificationPerformanceTests {
    func testQueryEfficiency() // Compare to baseline
    func testTimeComplexity() // Should be O(n*d) where n=nodes, d=depth
    func testMemoryUsage() // Should be O(n)
    func testScalability() // 3, 6, 12, 18, 24, 30 rooms
    func testCacheEffectiveness() // Avoid redundant computations
}
```

## Error Handling Tests

### Robustness Validation
```swift
class ErrorHandlingTests {
    func testHandlesInvalidGraph()
    func testHandlesDisconnectedGraph()
    func testHandlesInfiniteLoops()
    func testHandlesAPIFailures()
    func testGracefulDegradation()
    func testRecoveryStrategies()
    func testErrorMessages() // Clear, actionable
}
```

## Test Data Fixtures

### Graph Factory
```swift
class TestGraphFactory {
    static func createThreeRoomGraph() -> Graph
    static func createSixRoomGraph() -> Graph
    static func createAmbiguousGraph() -> Graph // Many same labels
    static func createUniqueLabelsGraph() -> Graph // All different
    static func createComplexGraph() -> Graph // Deep connections
    static func createPathologicalGraph() -> Graph // Worst case
}
```

### Expected Results
```swift
class ExpectedResults {
    static let threeRoomSignatures: [String]
    static let sixRoomSignatures: [String]
    static let optimalQueryCounts: [Int: Int] // rooms -> queries
}
```

## Code Quality Metrics

### Per Method Requirements
- **100% code coverage** from tests
- **<100ms** execution time for typical inputs
- **O(1) or O(n)** complexity where possible
- **Clear error messages** for failures
- **No external dependencies** (except sourceGraph)
- **Thread-safe** where applicable

### Overall Requirements
- **Zero compiler warnings**
- **SwiftLint compliance**
- **Documentation comments** for public methods
- **Complexity score** < 10 per method (cyclomatic)

## Test Execution Strategy

### Test Pyramid
```
Unit Tests (100+)        ████████████████████
Integration Tests (10)   ████████
Performance Tests (5)    ████
E2E Tests (3)           ██
```

### Continuous Testing
1. Unit tests run on every save
2. Integration tests run on every commit
3. Performance tests run on PR
4. Full suite runs on merge

## Total Test Count

### Unit Tests (Phases 1-5 Complete)
- Path Generation: 12 tests ✅
- Exploration: 11 tests ✅
- Graph Building: 12 tests ✅
- Label Analysis: 12 tests ✅
- Signature Computation: 12 tests ✅
- Signature Comparison: 12 tests ✅

### Unit Tests (Phases 6-7 Pending)
- Room Identification: 12 tests
- Orchestration: 12 tests
- Main Algorithm: 9 tests

### Integration Tests (Expanded for Phases 1-5)
- Three-Room Layout: 10 tests
- Six-Room Hexagon: 10 tests
- Algorithm Flow: 10 tests
- Signature System: 10 tests
- Edge Cases: 10 tests
- Original Integration: 8 tests

### Performance & Error Tests
- Performance: 5 tests
- Error Handling: 7 tests

**Current Total: 128 tests implemented**
**Target Total: 174 tests (with expanded integration)**

## Implementation Order

1. **Phase 1**: Core Data Structures (Node, Graph, PathResult, etc.)
2. **Phase 2**: Path Generation Layer (easiest to test)
3. **Phase 3**: Signature Computation (pure functions)
4. **Phase 4**: Graph Building (depends on structures)
5. **Phase 5**: Exploration Layer (uses graph)
6. **Phase 6**: Analysis & Comparison
7. **Phase 7**: Orchestration
8. **Phase 8**: Main Algorithm
9. **Phase 9**: Integration & Performance

Each phase should be fully tested before moving to the next.