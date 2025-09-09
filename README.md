# randomfun2025swift
Swift Repository for ICFP Contests 2025 of `Lambda Quakers` team

# Installation

For installation you need to follow instruction from the [Official Site](https://www.swift.org/install/)

# Making sure it works

These commands should work just fine

### Running a simple worker
```
swift run icfpworker
```

### Tests
```
swift test
```

### Implementation details

For the lighting round the `FindEverythingWorker` was used. The idea was to try to go through the graph randomly at first, then create all nodes and mark those nodes as "possible" rooms. Each node has an array of the possibilities, which room it was. At start, all rooms has possibility to be any of the N rooms of the problems. Each time we find a room, if possible we mark it as new distinct room, and compare it whether other rooms is possibly are the same. 

Isdifferent method was used, which basically tried to go through all known connections and compare them. If one of them was not possible, we knew that nodes were different, and, therefore, we removed those from possbilities array.

For every iteration the algorithm tried to explore first, find all new information from the server, and then update the graph, trying to compact it, by removing possibilities from the nodes. At some point, nodes would collapse to one possibile room, and we would know that the new room was found.

Once all distinc rooms were found, the algrorightm would try to move through the all doors of those rooms, to understand where the doors lead to.

Only after all the doors were explored, the algorightm would try to create map of the library, and define the door to door connections.

```
flowchart TD
    A[Start] --> B[Initialize FindEverythingWorker]
    B --> C[Create nodes as you explore randomly]
    C --> D[For each node: set Possibilities = All N rooms]
    
    subgraph Main Loop
      direction TB
      E[Explore server for new info] --> F[Update graph with discovered connections]
      F --> G[For each node pair, run IsDifferent]
      G --> H{Any connection impossible?}
      H -- Yes --> I[Mark nodes as different]
      I --> J[Remove invalid rooms from each node's Possibilities]
      H -- No --> K[Keep possibilities unchanged]
      J --> L{Did any node collapse to 1 room?}
      K --> L
      L -- Yes --> M[Confirm distinct room found\nand label node with that room]
      L -- No --> N[Continue iterating]
      M --> O[Propagate constraints to neighbors]
      O --> P[Try to compact graph further]
      P --> E
      N --> E
    end


    D --> E
    P --> Q{All nodes resolved?}
    Q -- Yes --> R[Done]
    Q -- No --> E
```

### Example

This is and exaple of the potential graph, after movement.

```
graph LR
graph LR

  %% Room 0
  subgraph Room0["Room 1?"]
    Room0Circle(("0"))
    Room0Circle --> R0D0["0"]
    %% Room0Circle --> R0D1["1"]
    %% Room0Circle --> R0D2["2"]
    %% Room0Circle --> R0D3["3"]
    %% Room0Circle --> R0D4["4"]
    %% Room0Circle --> R0D5["5"]
  end

  %% Room 1
  subgraph Room1["Room 2?"]
    Room1Circle(("1"))
    Room1Circle --> R1D0["0"]
    %% Room1Circle --> R1D1["1"]
    %% Room1Circle --> R1D2["2"]
    %% Room1Circle --> R1D3["3"]
    %% Room1Circle --> R1D4["4"]
    %% Room1Circle --> R1D5["5"]
  end

  %% Room 2
  subgraph Room2["Room 3?"]
    Room2Circle(("0"))
    Room2Circle --> R2D0["0"]
    %% Room2Circle --> R2D1["1"]
    %% Room2Circle --> R2D2["2"]
    %% Room2Circle --> R2D3["3"]
    %% Room2Circle --> R2D4["4"]
    %% Room2Circle --> R2D5["5"]
  end

  R0D0 -.-> Room1
  R1D0 -.-> Room2
  R2D0 -.-> Room0

```

Algrorith would reason as follows:

1. The Room1 is distinct, since no other rooms has `0` label
2. After move to Room2, Room2 is distincs, since no other rooms has `1` label
3. After move to Room3, we don't know, whether it distint or not, since it has `0` label, so potentially it can be Room1
4. After move from Room3 to Room0 we know that Room3 is distinct, since we moved through door `0` and we found different label, than when we were doing the same from the Room1


### After-lighting round

After-lighting round the algorithm was changed to use more sophisticated approach to find the map of the library.
Since comparing one room to another was not enough for these maps, the algorithm was updated slightly.

Once exploration performed, then next move was to perform 'pings' movements, which were doing the next:
- For the known path, if we are starting from the `bound` room, we could charcoal it, and check if the values of the known path changed.
- If the values from the known path changed, then we know that the room is distinct. And we can collapse those to the `bound` one.
- Additionaly, we were trying to select the room, where it was potentially the `bound` room, and check if the values of the known path changed.
- If the value of the room we were intereseted it wasn't changed, we removed the possiblity of being the `bound` room.
- In the best case scenario, this would generate a new distinct room, and we can proceed with the next room.

```
flowchart LR
    subgraph Room1
    R0((0))
    end
    R1((1))
    R2((2))
    R3((3))
    R4((0))
    R5((0))
    R6((2))
    subgraph Potentially Room1
    R7((0*))
    end

    R0 --> R1 --> R2 --> R3 --> R4 --> R5 --> R6 --> R7

```

```
flowchart LR
    subgraph Room1-Marked
    R0((1*))
    end
    R1((1))
    R2((2))
    R3((3))
    subgraph Room4
     %% notes
    Note0[[Not Room1]]
    R4((0))
    end
    subgraph Room1
    Note1[[Room1!]]
    Note2[[Changed]]
    R5((1*))
    end
    R6((2))
    subgraph Not Room1
    Note5[[Not changed]]
    R7((0*))
    end

    R0 --> R1 --> R2 --> R3 --> R4 --> R5 --> R6 --> R7
```
    



# Notes

- The algorithm is far from perfect and generates too many rooms to cover. It is always not enought information to collapse rooms, so "unbound" rooms are growing and growing and growing...
- Anyways, the algorithm is working and generates the map of the library.
- Comparation of the rooms through isDifferent method was too slow, since if deep was big enough, and the rooms were basically the same, then the results was 'likely not different' but we werent' able to know for sure that they are the same.


# Final thoughts

It was func to participate. The Team Mood was great, and we had a lot of fun.
See you next year!
