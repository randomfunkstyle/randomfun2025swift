import Foundation

/// Builds room understanding incrementally by exploring paths of increasing length
public class IncrementalRoomBuilder {
    
    /// Represents a candidate room that might be split or merged
    public struct RoomCandidate {
        public let id: Int
        public var label: Int
        public var states: Set<String>
        public var connectionSignature: [Int: Int?] = [:] // door -> target label
        
        public init(id: Int, label: Int, states: Set<String> = []) {
            self.id = id
            self.label = label
            self.states = states
            // Initialize all 6 doors as unknown
            for door in 0..<6 {
                connectionSignature[door] = nil
            }
        }
    }
    
    private var roomCandidates: [RoomCandidate] = []
    private var stateToRoomId: [String: Int] = [:]
    private var stateLabels: [String: Int] = [:]
    public private(set) var exploredPaths: Set<String> = []
    private var maxPathLength: Int
    private var roomIdCounter = 0
    
    public init(maxPathLength: Int = 20) {
        self.maxPathLength = maxPathLength
    }
    
    /// Process exploration results incrementally
    public func processExplorations(paths: [String], results: [[Int]]) {
        for (path, labels) in zip(paths, results) {
            processPath(path, labels: labels)
        }
        
        // Don't split aggressively - only merge compatible rooms
        // validateAndSplitRooms()  // Commenting out aggressive splitting
        
        // Debug: print current room configuration
        let debug = false  // Set to true for debugging
        if debug {
            print("\n🔍 DEBUG - Current rooms after processing:")
            for room in roomCandidates {
                print("  Room \(room.id) (label \(room.label)): \(room.states.count) states")
                let neighbors = getNeighborLabels(from: room.connectionSignature, myLabel: room.label)
                print("    Neighbors: \(neighbors)")
            }
        }
    }
    
    /// Process a single exploration path and its labels
    private func processPath(_ path: String, labels: [Int]) {
        var currentState = ""
        
        // Process each prefix of the path
        for i in 0..<min(path.count, labels.count - 1) {
            let label = labels[i]
            
            // Store state label
            stateLabels[currentState] = label
            exploredPaths.insert(currentState)
            
            // Find or create room for this state
            let roomId = findOrCreateRoom(state: currentState, label: label)
            
            // Move to next state
            if i < path.count {
                let door = String(path[path.index(path.startIndex, offsetBy: i)])
                if let doorNum = Int(door) {
                    let nextState = currentState + door
                    let nextLabel = labels[i + 1]
                    
                    // Update connection signature
                    updateRoomConnection(roomId: roomId, door: doorNum, targetLabel: nextLabel)
                    
                    currentState = nextState
                }
            }
        }
        
        // Process final state
        if labels.count > path.count {
            stateLabels[currentState] = labels[path.count]
            exploredPaths.insert(currentState)
            findOrCreateRoom(state: currentState, label: labels[path.count])
        }
        
        // After processing new information, merge rooms if needed
        mergeEquivalentRooms()
    }
    
    /// Find existing room or create new one for a state
    private func findOrCreateRoom(state: String, label: Int) -> Int {
        // Check if we already assigned this state to a room
        if let existingRoomId = stateToRoomId[state] {
            return existingRoomId
        }
        
        // Get connection signature for this state  
        let signature = getConnectionSignature(state)
        
        // Count how many non-self-loop connections we know about
        let knownConnections = signature.values.compactMap { $0 }.filter { $0 != label }.count
        
        // Find candidate rooms with same label
        for i in 0..<roomCandidates.count {
            if roomCandidates[i].label == label {
                // If we don't have enough information yet, be conservative
                if knownConnections < 2 {
                    // Check if this could be the same room based on what we know
                    if signaturesCompatible(roomCandidates[i].connectionSignature, signature) {
                        // Add state to this room tentatively
                        roomCandidates[i].states.insert(state)
                        stateToRoomId[state] = roomCandidates[i].id
                        
                        // Merge signature information
                        mergeSignatures(&roomCandidates[i].connectionSignature, signature)
                        
                        return roomCandidates[i].id
                    }
                } else {
                    // We have enough info - check if neighbor patterns match
                    let existingNeighbors = getNeighborLabels(from: roomCandidates[i].connectionSignature, myLabel: label)
                    let newNeighbors = getNeighborLabels(from: signature, myLabel: label)
                    
                    // If neighbor patterns match, it's likely the same room
                    if existingNeighbors == newNeighbors {
                        roomCandidates[i].states.insert(state)
                        stateToRoomId[state] = roomCandidates[i].id
                        mergeSignatures(&roomCandidates[i].connectionSignature, signature)
                        return roomCandidates[i].id
                    }
                }
            }
        }
        
        // No compatible room found - create new one
        var newRoom = RoomCandidate(id: roomIdCounter, label: label, states: [state])
        newRoom.connectionSignature = signature
        roomIdCounter += 1
        
        roomCandidates.append(newRoom)
        stateToRoomId[state] = newRoom.id
        
        return newRoom.id
    }
    
    /// Get sorted list of neighbor labels from a signature
    private func getNeighborLabels(from signature: [Int: Int?], myLabel: Int) -> [Int] {
        var neighbors: [Int] = []
        for (_, label) in signature {
            if let l = label, l != myLabel {
                neighbors.append(l)
            }
        }
        return neighbors.sorted()
    }
    
    /// Get connection signature for a state
    private func getConnectionSignature(_ state: String) -> [Int: Int?] {
        var signature: [Int: Int?] = [:]
        
        for door in 0..<6 {
            let nextState = state + String(door)
            if let nextLabel = stateLabels[nextState] {
                signature[door] = nextLabel
            } else {
                signature[door] = nil
            }
        }
        
        return signature
    }
    
    /// Get extended signature that includes neighbor label pattern
    private func getExtendedSignature(_ state: String) -> String {
        let myLabel = stateLabels[state] ?? -1
        var neighborLabels: [Int] = []
        
        // Collect labels of all neighboring rooms (excluding self-loops)
        for door in 0..<6 {
            let nextState = state + String(door)
            if let nextLabel = stateLabels[nextState], nextLabel != myLabel {
                neighborLabels.append(nextLabel)
            }
        }
        
        // Sort to create canonical form
        neighborLabels.sort()
        
        // Create unique signature: "label:[neighbor1,neighbor2,...]"
        return "\(myLabel):[\(neighborLabels.map(String.init).joined(separator: ","))]"
    }
    
    /// Check if two signatures are compatible (don't contradict)
    private func signaturesCompatible(_ sig1: [Int: Int?], _ sig2: [Int: Int?]) -> Bool {
        // Check for any direct contradictions
        for door in 0..<6 {
            if let label1 = sig1[door], let label1Val = label1,
               let label2 = sig2[door], let label2Val = label2 {
                if label1Val != label2Val {
                    return false  // Direct contradiction - these can't be the same room
                }
            }
        }
        return true  // No contradictions found
    }
    
    /// Merge signature information
    private func mergeSignatures(_ target: inout [Int: Int?], _ source: [Int: Int?]) {
        for (door, label) in source {
            if label != nil && target[door] == nil {
                target[door] = label
            }
        }
    }
    
    /// Update room connection based on observed transition
    private func updateRoomConnection(roomId: Int, door: Int, targetLabel: Int) {
        for i in 0..<roomCandidates.count {
            if roomCandidates[i].id == roomId {
                roomCandidates[i].connectionSignature[door] = targetLabel
                break
            }
        }
    }
    
    /// Validate rooms and split those with conflicting states
    private func validateAndSplitRooms() {
        var roomsToSplit: [(index: Int, groups: [[String]])] = []
        
        for (index, room) in roomCandidates.enumerated() {
            if room.states.count > 1 {
                // Check if all states in this room have compatible signatures
                let stateGroups = groupStatesByConnectionPattern(room.states)
                
                if stateGroups.count > 1 {
                    roomsToSplit.append((index: index, groups: stateGroups))
                }
            }
        }
        
        // Split rooms (in reverse order to maintain indices)
        for (index, groups) in roomsToSplit.reversed() {
            splitRoom(at: index, into: groups)
        }
    }
    
    /// Group states by their actual connection patterns
    private func groupStatesByConnectionPattern(_ states: Set<String>) -> [[String]] {
        // Group states by their extended signature (includes neighbor patterns)
        var signatureGroups: [String: [String]] = [:]
        
        for state in states {
            let extSig = getExtendedSignature(state)
            signatureGroups[extSig, default: []].append(state)
        }
        
        // If we have multiple groups with same extended signature, 
        // further check with detailed connection patterns
        var finalGroups: [[String]] = []
        
        for (_, statesInGroup) in signatureGroups {
            if statesInGroup.count == 1 {
                finalGroups.append(statesInGroup)
            } else {
                // Further split by exact connection patterns
                var subgroups: [[String]] = []
                
                for state in statesInGroup {
                    let sig = getConnectionSignature(state)
                    
                    var foundSubgroup = false
                    for (subgroupIndex, subgroup) in subgroups.enumerated() {
                        let subgroupSig = getConnectionSignature(subgroup[0])
                        if strictSignaturesCompatible(sig, subgroupSig) {
                            subgroups[subgroupIndex].append(state)
                            foundSubgroup = true
                            break
                        }
                    }
                    
                    if !foundSubgroup {
                        subgroups.append([state])
                    }
                }
                
                finalGroups.append(contentsOf: subgroups)
            }
        }
        
        return finalGroups
    }
    
    /// Check if signatures are strictly compatible (for splitting)
    private func strictSignaturesCompatible(_ sig1: [Int: Int?], _ sig2: [Int: Int?]) -> Bool {
        // For strict compatibility, all known connections must match exactly
        for door in 0..<6 {
            if let label1 = sig1[door], let label1Val = label1,
               let label2 = sig2[door], let label2Val = label2 {
                if label1Val != label2Val {
                    return false
                }
            }
        }
        return true
    }
    
    /// Split a room into multiple rooms
    private func splitRoom(at index: Int, into groups: [[String]]) {
        let originalRoom = roomCandidates[index]
        
        // Remove original room
        roomCandidates.remove(at: index)
        
        // Create new rooms for each group
        for group in groups {
            var newRoom = RoomCandidate(id: roomIdCounter, label: originalRoom.label, states: Set(group))
            roomIdCounter += 1
            
            // Build signature from all states in the group
            var mergedSignature: [Int: Int?] = [:]
            for state in group {
                let sig = getConnectionSignature(state)
                mergeSignatures(&mergedSignature, sig)
            }
            newRoom.connectionSignature = mergedSignature
            
            // Update state mappings
            for state in group {
                stateToRoomId[state] = newRoom.id
            }
            
            roomCandidates.append(newRoom)
        }
    }
    
    /// Merge rooms that are equivalent based on their signatures
    private func mergeEquivalentRooms() {
        var roomsToMerge: [[Int]] = []  // Groups of room IDs to merge
        var processed = Set<Int>()
        
        for i in 0..<roomCandidates.count {
            if processed.contains(roomCandidates[i].id) { continue }
            
            var mergeGroup = [roomCandidates[i].id]
            processed.insert(roomCandidates[i].id)
            
            for j in (i+1)..<roomCandidates.count {
                if processed.contains(roomCandidates[j].id) { continue }
                
                // Check if rooms can be merged
                if roomCandidates[i].label == roomCandidates[j].label {
                    // Check if signatures are compatible
                    if signaturesCompatible(roomCandidates[i].connectionSignature, 
                                          roomCandidates[j].connectionSignature) {
                        mergeGroup.append(roomCandidates[j].id)
                        processed.insert(roomCandidates[j].id)
                    }
                }
            }
            
            if mergeGroup.count > 1 {
                roomsToMerge.append(mergeGroup)
            }
        }
        
        // Perform merges
        for group in roomsToMerge {
            mergeRooms(roomIds: group)
        }
    }
    
    /// Merge multiple rooms into one
    private func mergeRooms(roomIds: [Int]) {
        guard roomIds.count > 1 else { return }
        
        let targetId = roomIds[0]
        var targetIndex = roomCandidates.firstIndex(where: { $0.id == targetId })!
        
        // Merge all other rooms into the first one
        for roomId in roomIds.dropFirst() {
            if let sourceIndex = roomCandidates.firstIndex(where: { $0.id == roomId }) {
                // Merge states
                roomCandidates[targetIndex].states.formUnion(roomCandidates[sourceIndex].states)
                
                // Merge connection signatures
                mergeSignatures(&roomCandidates[targetIndex].connectionSignature,
                              roomCandidates[sourceIndex].connectionSignature)
                
                // Update state mappings
                for state in roomCandidates[sourceIndex].states {
                    stateToRoomId[state] = targetId
                }
            }
        }
        
        // Remove merged rooms (in reverse order to maintain indices)
        let idsToRemove = Set(roomIds.dropFirst())
        roomCandidates.removeAll { idsToRemove.contains($0.id) }
    }
    
    /// Get the final room assignments
    public func getFinalRooms() -> [StateTransitionAnalyzer.Room] {
        // Before returning, do a final split pass using complete information
        finalSplitPass()
        
        var rooms: [StateTransitionAnalyzer.Room] = []
        
        for candidate in roomCandidates {
            var room = StateTransitionAnalyzer.Room(
                id: candidate.id,
                label: candidate.label,
                states: candidate.states
            )
            
            // Set up door connections based on signature
            for (door, targetLabel) in candidate.connectionSignature {
                if let label = targetLabel {
                    // Find the room with this label that's connected
                    // For now, just mark as connected without specific target room
                    room.doors[door] = (toRoomId: label, toDoor: nil)
                }
            }
            
            rooms.append(room)
        }
        
        return rooms
    }
    
    /// Final pass to split rooms using complete information
    private func finalSplitPass() {
        var roomsToSplit: [(index: Int, groups: [[String]])] = []
        
        for (index, room) in roomCandidates.enumerated() {
            if room.states.count > 1 {
                // Group states by their full door-to-label mapping
                var stateGroups: [String: [String]] = [:]
                
                for state in room.states {
                    // Build complete door mapping
                    var doorMap: [Int: Int] = [:]
                    var unknownDoors = 0
                    
                    for door in 0..<6 {
                        let nextState = state + String(door)
                        if let nextLabel = stateLabels[nextState] {
                            doorMap[door] = nextLabel
                        } else {
                            unknownDoors += 1
                        }
                    }
                    
                    // Only split if we have enough information (at least 4 doors mapped)
                    if doorMap.count >= 4 {
                        // Create signature from complete door mapping
                        let sig = doorMap.sorted { $0.key < $1.key }
                            .map { "d\($0.key)→\($0.value)" }
                            .joined(separator: ",")
                        stateGroups[sig, default: []].append(state)
                    } else {
                        // Not enough info - don't split this state
                        stateGroups["partial_\(unknownDoors)", default: []].append(state)
                    }
                }
                
                // Only split if we have truly distinct complete patterns
                let completeGroups = stateGroups.filter { !$0.key.starts(with: "partial_") }
                if completeGroups.count > 1 {
                    // Check if the patterns are actually different
                    let patterns = completeGroups.keys.map { $0 }
                    if patterns.count > 1 {
                        var groups: [[String]] = Array(completeGroups.values)
                        
                        // Add partial states to the largest complete group
                        let partialStates = stateGroups.filter { $0.key.starts(with: "partial_") }
                            .flatMap { $0.value }
                        
                        if !partialStates.isEmpty {
                            // Find the largest group and add partial states to it
                            if let largestIndex = groups.indices.max(by: { groups[$0].count < groups[$1].count }) {
                                groups[largestIndex].append(contentsOf: partialStates)
                            }
                        }
                        
                        roomsToSplit.append((index: index, groups: groups))
                    }
                }
            }
        }
        
        // Perform splits (in reverse order to maintain indices)
        for (index, groups) in roomsToSplit.reversed() {
            if groups.count > 1 {  // Only split if we actually have multiple groups
                splitRoom(at: index, into: groups)
            }
        }
    }
    
    /// Get current room count
    public func getRoomCount() -> Int {
        return roomCandidates.count
    }
    
    /// Get statistics about current state
    public func getStatistics() -> (rooms: Int, states: Int, connections: Int) {
        let totalStates = roomCandidates.reduce(0) { $0 + $1.states.count }
        let totalConnections = roomCandidates.reduce(0) { room, candidate in
            room + candidate.connectionSignature.values.compactMap { $0 }.count
        }
        
        return (rooms: roomCandidates.count, states: totalStates, connections: totalConnections)
    }
}