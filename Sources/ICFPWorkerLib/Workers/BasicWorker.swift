

public final class BasicWorker: Worker {
    public override func generatePlans() -> [String] {
        return ["0", "1", "2"]
    }

    public override func generateGuess() -> MapDescription {
        return MapDescription(rooms: [0,1,2], startingRoom: 0, connections: [])
    }
}
