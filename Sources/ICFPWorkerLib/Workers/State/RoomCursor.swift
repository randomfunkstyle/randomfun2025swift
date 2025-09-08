final class RoomCursor {
    internal private(set) var room: ExplorationRoom
    init(room: ExplorationRoom) {
        self.room = room
    }
    
    
    func door(_ door: Int) -> ExploratoinDoor {
        room.doors[door]
    }
    func destinationByMoving    (_ door: Int) -> ExplorationRoom? {
        room.doors[door].destinationRoom
    }
    
    @discardableResult
    func moveToDoor(_ doorIdx: Int) -> ExplorationRoom? {
        let door = room.doors[doorIdx]
        guard let destinationRoom = door  .destinationRoom else {
            print("💥 Door \(door) in room \(room) has no destination room")
            return nil
        }
        updateDestinationDoors(destinationRoom, from: room, sourceDoor: door)
        room = destinationRoom
        return destinationRoom
    }
    
    /// Return random door that has a destination room
    func randomDoor() -> ExploratoinDoor? {
        room.doors.filter({ $0.destinationRoom != nil }).randomElement()
    }
    
    func randomMove() -> (id: Int, room: ExplorationRoom)? {
        guard let randomDoor = randomDoor() else {
            return nil
        }
        return (randomDoor.id, randomDoor.destinationRoom!)
    }
    
    // Let's update the doors of the ExplorationRoom
    func updateDestinationDoors(_ destinationRoom: ExplorationRoom, from: ExplorationRoom, sourceDoor: ExploratoinDoor) {
        guard !destinationRoom.externalDoorsConnections.contains(where: { $0 == sourceDoor }) else {
            return
        }
        
        // Let's add the door to the external doors connections
//        destinationRoom.externalDoorsConnections.append(sourceDoor)
        
        /// What can we get from here... should we analyze destination doors? Let's do this in the known state?
        /// :Thinking...
        
    }
}
