final class ExploratoinDoor {
    
    static var nextID = 0
    let serializationId: Int
    
    /// Id of the door, typically "0" to "5"
    let id: Int
    
    /// This si the room that this door leads to
    var destinationRoom: ExplorationRoom?
    
    /// This is the door in the destination room that leads back to this room
    weak var destinationDoor: ExploratoinDoor?

    // This is actually a weak reference to avoid retain cycles
    weak var owner: ExplorationRoom? = nil

    init(id: Int, owner: ExplorationRoom?) {
        self.id = id
        self.owner = owner
        self.serializationId = ExplorationRoom.nextID
        ExploratoinDoor.nextID += 1
    }

    
}



