# Six Rooms Bipartite Topology

```mermaid
graph TD
    A((A:0))
    B((B:1))
    C((C:2))
    D((D:3))
    E((E:0))
    F((F:1))
    
    %% Group 1: A, B, C
    %% Group 2: D, E, F
    
    A -.0.- D
    A -.1.- E
    A -.2.- F
    B -.0.- D
    B -.1.- E
    B -.2.- F
    C -.0.- D
    C -.1.- E
    C -.2.- F
    
    A --3,4,5--> A
    B --3,4,5--> B
    C --3,4,5--> C
    D --3,4,5--> D
    E --3,4,5--> E
    F --3,4,5--> F
```

## Config
```
ROOMS A:0 B:1 C:2 D:3 E:0 F:1
START A

A0 D0
A1 E0
A2 F0
A3 A3
A4 A4
A5 A5

B0 D1
B1 E1
B2 F1
B3 B3
B4 B4
B5 B5

C0 D2
C1 E2
C2 F2
C3 C3
C4 C4
C5 C5

D0 A0
D1 B0
D2 C0
D3 D3
D4 D4
D5 D5

E0 A1
E1 B1
E2 C1
E3 E3
E4 E4
E5 E5

F0 A2
F1 B2
F2 C2
F3 F3
F4 F4
F5 F5
```