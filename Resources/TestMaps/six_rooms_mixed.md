# Six Rooms Mixed Self-Loops

```mermaid
graph TD
    A((A:0))
    B((B:1))
    C((C:2))
    D((D:3))
    E((E:0))
    F((F:1))
    
    %% A has 0 self-loops (all doors connect out)
    %% B has 1 self-loop
    %% C has 2 self-loops
    %% D has 3 self-loops
    %% E has 4 self-loops
    %% F has 5 self-loops
    
    A -.0.- B
    A -.1.- C
    A -.2.- D
    A -.3.- E
    A -.4.- F
    A -.5.- B
    
    B --0--> B
    C --0--> C
    C --1--> C
    D --0--> D
    D --1--> D
    D --2--> D
    E --0--> E
    E --1--> E
    E --2--> E
    E --3--> E
    F --0--> F
    F --1--> F
    F --2--> F
    F --3--> F
    F --4--> F
```

## Config
```
ROOMS A:0 B:1 C:2 D:3 E:0 F:1
START A

A0 B1
A1 C2
A2 D3
A3 E4
A4 F5
A5 B2

B0 B0
B1 A0
B2 A5
B3 C3
B4 D4
B5 E5

C0 C0
C1 C1
C2 A1
C3 B3
C4 D5
C5 F3

D0 D0
D1 D1
D2 D2
D3 A2
D4 B4
D5 C4

E0 E0
E1 E1
E2 E2
E3 E3
E4 A3
E5 B5

F0 F0
F1 F1
F2 F2
F3 F3
F4 F4
F5 A4
```