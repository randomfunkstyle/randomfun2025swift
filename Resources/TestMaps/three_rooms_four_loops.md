# Three Rooms Four Loops

```mermaid
graph TD
    A((A:0))
    B((B:1))
    C((C:2))

    A -.4.- B
    A -.5.- C

    A --0--> A
    A --1--> A
    A --2--> A
    A --3--> A
    B --0--> B
    B --1--> B
    B --2--> B
    B --3--> B
    B --5--> B
    C --0--> C
    C --1--> C
    C --2--> C
    C --3--> C
    C --4--> C
```
