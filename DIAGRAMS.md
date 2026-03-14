# Project Diagrams

This document contains structural and behavioral diagrams for the Hostel Management System based on its models and architecture.

## 1. System Architecture Diagram
*Illustrates the offline-first Flutter application structure.*

```mermaid
graph TD
    classDef frontend fill:#1E88E5,stroke:#fff,color:#fff,rx:5px,ry:5px
    classDef state fill:#43A047,stroke:#fff,color:#fff,rx:5px,ry:5px
    classDef storage fill:#E53935,stroke:#fff,color:#fff,rx:5px,ry:5px
    classDef security fill:#8E24AA,stroke:#fff,color:#fff,rx:5px,ry:5px

    User((User)) --> UI
    
    subgraph "Flutter Application"
        UI[UI Components / Views]:::frontend
        Controllers[Provider State Management]:::state
        Services[Business Logic Services]:::state
        
        UI <-->|Listens / Dispatches| Controllers
        Controllers <--> Services
        
        subgraph "Local Persistence"
            Hive[(Hive Database\nPrimary Storage)]:::storage
            SecureStore[(Secure Storage\nKeys & Tokens)]:::security
        end
        
        Services <-->|Read / Encrypted Write| Hive
        Services <-->|Read / Write| SecureStore
    end
```

## 2. Use Case Diagram
*Shows the interactions between the Student/Staff and the system.*

```mermaid
usecase
    %% Mermaid usecase using graph (Actor to Use Case)
    %% Note: Standard flowchart used to mimic Use Case Diagram
```

Wait, `usecase` isn't standard in Mermaid, let me use `flowchart` to simulate standard UML Use Case or use Mermaid's requirement diagram? No, Mermaid doesn't strictly have a standard structural "Use Case" diagram syntax that renders perfectly everywhere except by using `flowchart` with stick figures or rectangles. Wait, `journey` or `mindmap`? Flowchart is best.

```mermaid
flowchart LR
    Student((Student))
    Staff((Hostel Staff))

    subgraph "Hostel Management System"
        UC1(Schedule Room Cleaning)
        UC2(Join Laundry Queue)
        UC3(View Machine Status)
        UC4(Update Cleaning Status)
        UC5(Verify Room Cleaning)
    end

    Student --> UC1
    Student --> UC2
    Student --> UC3

    Staff --> UC3
    Staff --> UC4
    Staff --> UC5
```

## 3. Entity Relationship (ER) Diagram
*Visualizes the core un-coupled data models stored in Hive.*

```mermaid
erDiagram
    STUDENT {
        string id PK
        string name
        string roomNumber
        string hostelBlock
    }
    
    ROOM_CLEANING {
        string id PK
        string roomNumber
        string floor
        string studentId FK
        string status
        dateTime scheduledDate
        dateTime completedAt
        string verifiedBy
        boolean bathroomClean
        boolean roomClean
        boolean toiletClean
    }
    
    WASHING_MACHINE {
        string id PK
        string location
        string status
        string currentUserId FK
        dateTime currentStartTime
        int cycleMinutes
    }
    
    QUEUE_ENTRY {
        string id PK
        string studentId FK
        string studentName
        string machineId FK
        dateTime timestamp
        int position
    }

    STUDENT ||--o{ ROOM_CLEANING : "schedules"
    STUDENT ||--o{ QUEUE_ENTRY : "joins"
    WASHING_MACHINE ||--o{ QUEUE_ENTRY : "has"
    STUDENT |o--o| WASHING_MACHINE : "currently uses"
```

## 4. Activity Diagram
*Shows the workflow of joining a laundry queue.*

```mermaid
stateDiagram-v2
    [*] --> CheckMachineStatus
    
    CheckMachineStatus --> IsAvailable: Machine exists
    
    state IsAvailable <<choice>>
    IsAvailable --> StartMachine: Machine Status == Available
    IsAvailable --> JoinQueue: Machine Status == InUse
    
    StartMachine --> SetCurrentUser
    SetCurrentUser --> UpdateMachineStatus
    UpdateMachineStatus --> [*]: Laundry Started
    
    JoinQueue --> CalculatePosition
    CalculatePosition --> CreateQueueEntry
    CreateQueueEntry --> [*]: Waiting in Queue
```

## 5. Sequence Diagram
*Details the process of scheduling a room cleaning.*

```mermaid
sequenceDiagram
    actor Student
    participant UI as Cleaning View
    participant Provider as CleaningController
    participant Hive as LocalStorage (Hive)

    Student->>UI: Selects Date & Time
    UI->>UI: Validates Input
    Student->>UI: Taps "Schedule Cleaning"
    UI->>Provider: scheduleCleaning(room, floor, date)
    
    activate Provider
    Provider->>Provider: Create RoomCleaning Model Status=Pending
    Provider->>Hive: saveCleaningRequest(Model)
    
    activate Hive
    Hive-->>Provider: Success
    deactivate Hive
    
    Provider->>Provider: notifyListeners()
    Provider-->>UI: Update State
    deactivate Provider
    
    UI-->>Student: Show Success Snackbar
```
