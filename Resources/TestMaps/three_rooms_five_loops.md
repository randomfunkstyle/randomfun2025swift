# Three Rooms Five Self-Loops Each

```mermaid
graph TD
    A((A:0))
    B((B:1))
    C((C:2))
    
    A -.5.- B
    B -.5.- C
    
    A --0,1,2,3,4--> A
    B --0,1,2,3,4--> B
    C --0,1,2,3,4--> C
```

## Config
```
ROOMS A:0 B:1 C:2
START A

A0 A0
A1 A1
A2 A2
A3 A3
A4 A4
A5 B5

B0 B0
B1 B1
B2 B2
B3 B3
B4 B4
B5 C5

C0 C0
C1 C1
C2 C2
C3 C3
C4 C4
C5 B5
```