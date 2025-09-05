# Two Rooms Single Connection

```mermaid
graph TD
    A((A:0))
    B((B:1))
    
    A -.0.- B
    A --1--> A
    A --2--> A
    A --3--> A
    A --4--> A
    A --5--> A
    B --1--> B
    B --2--> B
    B --3--> B
    B --4--> B
    B --5--> B
```

## Config
```
ROOMS A:0 B:1
START A

A0 B0
A1 A1
A2 A2
A3 A3
A4 A4
A5 A5
B0 A0
B1 B1
B2 B2
B3 B3
B4 B4
B5 B5
```