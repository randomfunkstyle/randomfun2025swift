# Six Rooms Star Topology

```mermaid
graph TD
    A((A:0))
    B((B:1))
    C((C:2))
    D((D:3))
    E((E:0))
    F((F:1))
    
    A -.1.- B
    A -.2.- C
    A -.3.- D
    A -.4.- E
    A -.5.- F
    
    A --0--> A
    B --1--> B
    B --2--> B
    B --3--> B
    B --4--> B
    B --5--> B
    C --1--> C
    C --2--> C
    C --3--> C
    C --4--> C
    C --5--> C
    D --1--> D
    D --2--> D
    D --3--> D
    D --4--> D
    D --5--> D
    E --1--> E
    E --2--> E
    E --3--> E
    E --4--> E
    E --5--> E
    F --1--> F
    F --2--> F
    F --3--> F
    F --4--> F
    F --5--> F
```

## Config
```
ROOMS A:0 B:1 C:2 D:3 E:0 F:1
START A

A0 A0
A1 B0
A2 C0
A3 D0
A4 E0
A5 F0

B0 A1
B1 B1
B2 B2
B3 B3
B4 B4
B5 B5

C0 A2
C1 C1
C2 C2
C3 C3
C4 C4
C5 C5

D0 A3
D1 D1
D2 D2
D3 D3
D4 D4
D5 D5

E0 A4
E1 E1
E2 E2
E3 E3
E4 E4
E5 E5

F0 A5
F1 F1
F2 F2
F3 F3
F4 F4
F5 F5
```