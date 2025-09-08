final class ExploratoinDoor: Equatable, CustomStringConvertible {
    
    static var nextID = 0
    let serializationId: Int
    
    /// Id of the door, typically "0" to "5"
    let id: Int
    
    /// This si the room that this door leads to
    var destinationRoom: ExplorationRoom?
    
    /// This is the door in the destination room that leads back to this room
    var destinationDoor: ExploratoinDoor?

    // This is actually a weak reference to avoid retain cycles
    var owner: ExplorationRoom? = nil

    init(id: Int, owner: ExplorationRoom?) {
        self.id = id
        self.owner = owner
        self.serializationId = ExplorationRoom.nextID
        ExploratoinDoor.nextID += 1
    }

    static func == (lhs: ExploratoinDoor, rhs: ExploratoinDoor) -> Bool {
        return lhs.serializationId == rhs.serializationId
    }
    
    var description: String {
        let ownerId = owner!.serializationId
        let destRoomId = (destinationRoom?.serializationId).map { String($0) } ?? "nil"
        let destDoorId = (destinationDoor?.serializationId).map { String($0) } ?? "nil"
        return "Door(id: \(id), owner: \(ownerId), destRoom: \(destRoomId), destDoor: \(destDoorId))"
    }
}



