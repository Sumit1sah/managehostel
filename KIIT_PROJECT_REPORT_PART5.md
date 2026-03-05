### 3.3.2 System Architecture

The Hostel Management System follows a layered architecture pattern with clear separation of concerns, promoting maintainability, testability, and scalability.

**Architectural Overview:**

The system architecture consists of four primary layers:

**1. Presentation Layer (UI Layer)**

This layer contains all user interface components and handles user interactions. It is responsible for:
- Rendering screens and widgets
- Capturing user input
- Displaying data from lower layers
- Providing visual feedback
- Implementing navigation

Components:
- Views: Complete screens (LoginView, DashboardView, RoomCleaningView, etc.)
- Widgets: Reusable UI components (custom buttons, cards, dialogs)
- Themes: Visual styling and theming
- Localization: Multi-language support

The presentation layer depends on the business logic layer through Provider pattern but remains independent of data storage implementation.

**2. Business Logic Layer (Service Layer)**

This layer contains application logic, business rules, and use case implementations. It mediates between presentation and data layers. Responsibilities include:
- Processing user actions
- Implementing business rules
- Coordinating data operations
- Managing application state
- Handling workflows

Components:
- Services: Business logic implementations (AuthService, CleaningService, WashingService)
- Controllers: UI-specific logic (CleaningController, WashingController)
- Providers: State management (AppStateProvider, ThemeProvider, LocaleProvider)
- Validators: Input validation and sanitization

**3. Data Layer (Persistence Layer)**

This layer handles all data operations including storage, retrieval, and management. It abstracts storage implementation from upper layers. Responsibilities include:
- Data persistence to local database
- Data retrieval and querying
- Encryption and decryption
- Data migration and versioning
- Cache management

Components:
- Storage Services: HiveStorage (encrypted database), SecureStorage (keychain wrapper)
- Models: Data structures (Student, RoomCleaning, WashingMachine, QueueEntry)
- Repositories: Data access abstractions (for future cloud integration)

**4. Core Layer (Foundation Layer)**

This layer provides fundamental functionality used across all other layers:
- Application lifecycle management
- Dependency injection
- Error handling and logging
- Constants and configurations
- Utility functions

Components:
- AppLifecycleObserver: Handles app pause/resume for data saving
- Constants: Application-wide constants
- Utilities: Helper functions and extensions

**Data Flow Architecture:**

**Write Flow (User Action to Storage):**
1. User interacts with UI (e.g., marks room as clean)
2. View calls method on Provider/Controller
3. Provider updates in-memory state
4. Provider calls notifyListeners() triggering UI rebuild
5. Provider triggers debounced save (500ms delay)
6. Service layer validates and processes data
7. Storage layer encrypts and persists data to Hive
8. On app pause: Force immediate save bypassing debounce

**Read Flow (Storage to UI):**
1. App starts, SplashView displayed
2. Storage layer initializes Hive with encryption key from keystore
3. Providers load data from storage into memory
4. Navigation restored to last screen
5. UI renders with restored data
6. Subsequent reads served from in-memory state (fast)

**State Management Architecture:**

The system uses Provider pattern for state management with the following structure:

**AppStateProvider:** Global application state including:
- User session and authentication status
- Navigation state
- Cached data (announcements, mess menu)
- Application preferences

**ThemeProvider:** Theme-related state:
- Current theme mode (light/dark/system)
- Theme persistence

**LocaleProvider:** Localization state:
- Current language/locale
- Locale persistence

**Feature-Specific Controllers:** Domain-specific state:
- CleaningController: Room cleaning state
- WashingController: Queue management state

**Security Architecture:**

**Encryption Layer:**
- All Hive boxes encrypted with AES-256
- Encryption key generated on first launch using cryptographically secure RNG
- Key stored in platform keystore (iOS Keychain / Android Keystore)
- Credentials stored in flutter_secure_storage

**Access Control:**
- Role-based access control (Student, Parent, Warden)
- Permission checks before sensitive operations
- Warden password verification for critical actions

**Data Protection:**
- Input validation and sanitization
- No sensitive data in logs
- Secure session management
- Automatic session timeout

**Offline-First Architecture:**

The system is designed to function completely offline:

**Local-First Data:**
- All data stored locally in encrypted Hive database
- No network calls required for core functionality
- Instant data access without latency

**State Persistence:**
- Continuous state saving with debounced writes
- Complete state restoration on app restart
- No data loss on unexpected termination

**Future Cloud Integration:**
- Architecture supports adding cloud sync layer
- Local database serves as cache
- Sync queue for pending operations
- Conflict resolution strategies prepared

**Scalability Considerations:**

**Horizontal Scalability:**
- Architecture supports multiple hostel instances
- Each instance operates independently
- Future cloud backend can coordinate multiple instances

**Vertical Scalability:**
- Efficient data structures minimize memory usage
- Lazy loading for large datasets
- Pagination for long lists
- Database indexing for fast queries

**Feature Scalability:**
- Modular architecture allows adding features without modifying existing code
- Plugin architecture for optional features
- Clear interfaces between layers

**Technology Stack:**

**Frontend:**
- Flutter 3.0+ (UI framework)
- Dart 2.17+ (programming language)
- Material Design (design system)

**State Management:**
- Provider 6.1+ (state management)
- ChangeNotifier (reactive updates)

**Database:**
- Hive 2.2+ (NoSQL database)
- Hive Flutter (Flutter integration)

**Security:**
- flutter_secure_storage 9.0+ (keychain wrapper)
- crypto 3.0+ (encryption utilities)

**Additional Libraries:**
- image_picker (photo capture)
- url_launcher (external links)
- share_plus (data sharing)
- pdf (PDF generation)
- path_provider (file system access)
- intl (internationalization)

### 3.3.3 Block Diagram

**[BLOCK DIAGRAM DESCRIPTION - To be inserted as image]**

The system block diagram illustrates the high-level architecture and component interactions:

**User Interface Layer:**
- Student App Interface
- Parent App Interface
- Warden App Interface

Connected to:

**Application Layer:**
- Authentication Module
- Dashboard Module
- Room Management Module
- Queue Management Module
- Leave Management Module
- Complaint Module
- Announcement Module
- Settings Module

Connected to:

**Business Logic Layer:**
- Auth Service
- Cleaning Service
- Washing Service
- Storage Service
- Notification Service

Connected to:

**Data Layer:**
- Hive Encrypted Database
  - Users Box
  - Cleaning Box
  - Queue Box
  - Leaves Box
  - Complaints Box
  - Announcements Box
- Secure Storage (Keychain/Keystore)
  - Encryption Keys
  - User Credentials
  - Session Tokens

**External Interfaces:**
- Device Camera (for photos)
- File System (for exports)
- Platform Services (notifications, sharing)

**Data Flow Arrows:**
- User interactions flow from UI to Application Layer
- Application Layer calls Business Logic Layer
- Business Logic Layer reads/writes to Data Layer
- Data Layer encrypts/decrypts data
- Responses flow back up the layers

### 3.3.4 UML Diagrams

**Use Case Diagram:**

**[USE CASE DIAGRAM DESCRIPTION - To be inserted as image]**

**Actors:**
1. Student
2. Parent
3. Warden

**Student Use Cases:**
- Login to System
- View Dashboard
- Manage Room Cleaning
  - View Cleaning Status
  - Mark Items as Clean
  - Submit for Verification
- Manage Washing Queue
  - View Available Machines
  - Join Queue
  - Track Position
  - Leave Queue
- Apply for Leave
  - Submit Application
  - Track Status
- Register Complaint
  - Create Complaint
  - Attach Photos
  - Track Resolution
- View Announcements
- View Mess Menu
- View Holiday List
- View Room Availability
- Manage Profile
- Change Settings
- Logout

**Parent Use Cases:**
- Login to System
- View Ward Dashboard
- View Ward Information
- Approve/Reject Leave
- Communicate with Warden
- View Announcements
- Logout

**Warden Use Cases:**
- Login to System
- View Admin Dashboard
- Manage Students
  - Add Student
  - Edit Student
  - Delete Student
  - Allocate Room
  - Swap Room
- Verify Room Cleaning
- Approve/Reject Leave Applications
- Manage Complaints
  - View Complaints
  - Update Status
  - Resolve Issues
- Create Announcements
- View Parent Messages
- Generate Reports
- Export Data
- Logout

**Class Diagram:**

**[CLASS DIAGRAM DESCRIPTION - To be inserted as image]**

**Core Classes:**

**Student**
- Attributes: userId, name, email, phone, floor, room, block, password
- Methods: toJson(), fromJson(), validate()

**Parent**
- Attributes: parentId, studentId, name, phone, password
- Methods: toJson(), fromJson(), linkStudent()

**Warden**
- Attributes: wardenId, name, email, password, assignedFloors
- Methods: toJson(), fromJson(), authenticate()

**RoomCleaning**
- Attributes: roomNumber, floor, studentId, status, bathroomClean, roomClean, toiletClean, submittedAt, verifiedAt
- Methods: toJson(), fromJson(), isComplete(), submit(), verify()

**WashingMachine**
- Attributes: machineId, location, status, currentUser, cycleStartTime, cycleEndTime
- Methods: toJson(), fromJson(), startCycle(), completeCycle(), isAvailable()

**QueueEntry**
- Attributes: entryId, studentId, studentName, machineId, position, joinedAt, estimatedWaitTime
- Methods: toJson(), fromJson(), updatePosition(), calculateWaitTime()

**LeaveApplication**
- Attributes: applicationId, studentId, leaveType, startDate, endDate, reason, parentStatus, wardenStatus, submittedAt
- Methods: toJson(), fromJson(), approve(), reject(), getStatus()

**Complaint**
- Attributes: complaintId, studentId, category, description, status, photoPath, createdAt, resolvedAt
- Methods: toJson(), fromJson(), updateStatus(), resolve()

**Announcement**
- Attributes: announcementId, title, content, category, priority, createdBy, createdAt, targetAudience
- Methods: toJson(), fromJson(), isUrgent()

**Service Classes:**

**AuthService**
- Methods: login(), logout(), isLoggedIn(), getUserId(), changePassword()

**CleaningService**
- Methods: getRoomCleaning(), updateCleaning(), submitForVerification(), verifyCleaning()

**WashingService**
- Methods: getAvailableMachines(), joinQueue(), leaveQueue(), progressQueue(), getQueuePosition()

**StorageService**
- Methods: save(), load(), delete(), clear(), export()

**HiveStorage**
- Methods: init(), save(), load(), loadList(), delete(), encrypt(), decrypt()

**SecureStorage**
- Methods: write(), read(), delete(), deleteAll()

**Provider Classes:**

**AppStateProvider**
- Attributes: currentUser, isAuthenticated, navigationState
- Methods: login(), logout(), updateState(), saveState(), restoreState()

**ThemeProvider**
- Attributes: themeMode
- Methods: setTheme(), toggleTheme(), saveTheme()

**LocaleProvider**
- Attributes: locale
- Methods: setLocale(), saveLocale()

**Relationships:**
- Student, Parent, Warden inherit from User (base class)
- RoomCleaning associated with Student
- QueueEntry associated with Student and WashingMachine
- LeaveApplication associated with Student
- Complaint associated with Student
- Services depend on Storage classes
- Providers depend on Services
- Views depend on Providers

**Sequence Diagram: Room Cleaning Submission**

**[SEQUENCE DIAGRAM DESCRIPTION - To be inserted as image]**

**Actors:** Student, UI, CleaningController, CleaningService, HiveStorage

**Flow:**
1. Student opens Room Cleaning screen
2. UI requests cleaning data from CleaningController
3. CleaningController loads data from CleaningService
4. CleaningService retrieves from HiveStorage
5. HiveStorage decrypts and returns data
6. Data flows back to UI, screen renders
7. Student checks "Bathroom Clean" checkbox
8. UI calls updateCleaning() on CleaningController
9. CleaningController updates state
10. CleaningController notifies listeners
11. UI rebuilds with updated state
12. CleaningController triggers debounced save
13. After 500ms, save executes
14. CleaningService validates data
15. HiveStorage encrypts and persists data
16. Student checks remaining items
17. Student clicks "Submit for Verification"
18. UI calls submitForVerification()
19. CleaningController validates all items checked
20. CleaningService updates status to "Submitted"
21. HiveStorage persists updated status
22. UI shows success message
23. Warden receives notification (future feature)

**Sequence Diagram: Washing Machine Queue**

**[SEQUENCE DIAGRAM DESCRIPTION - To be inserted as image]**

**Actors:** Student, UI, WashingController, WashingService, HiveStorage

**Flow:**
1. Student opens Washing Queue screen
2. UI requests available machines
3. WashingController loads from WashingService
4. WashingService retrieves from HiveStorage
5. Data returned showing machine status and queues
6. Student selects machine and clicks "Join Queue"
7. UI calls joinQueue() on WashingController
8. WashingController validates student not already in queue
9. WashingService creates QueueEntry
10. WashingService calculates position and wait time
11. HiveStorage persists queue entry
12. WashingController notifies listeners
13. UI updates showing student in queue
14. Student navigates to Queue Tracking screen
15. UI displays real-time position
16. When student's turn arrives (automated or manual)
17. WashingService calls progressQueue()
18. Current user removed, next user becomes current
19. HiveStorage updates machine and queue state
20. UI shows "Your turn!" notification
21. After 45 minutes, cycle completes
22. WashingService marks machine available
23. Queue progresses to next student

**Activity Diagram: Leave Application Workflow**

**[ACTIVITY DIAGRAM DESCRIPTION - To be inserted as image]**

**Start:** Student decides to apply for leave

**Activities:**
1. Student opens Leave Application screen
2. Student fills form (leave type, dates, reason)
3. System validates dates (end >= start, future dates)
4. If invalid: Show error, return to form
5. If valid: Student submits application
6. System creates LeaveApplication with status "Pending Parent Approval"
7. System saves to database
8. System shows success message to student
9. Parent logs in to parent portal
10. Parent views pending leave applications
11. Parent reviews application details
12. Decision point: Approve or Reject?
13. If Reject:
    - Parent enters rejection reason
    - System updates status to "Rejected by Parent"
    - Student notified
    - End
14. If Approve:
    - Parent clicks approve
    - System updates status to "Pending Warden Approval"
    - Warden receives notification
15. Warden logs in to warden dashboard
16. Warden views pending leave applications
17. Warden reviews application
18. Decision point: Approve or Reject?
19. If Reject:
    - Warden enters rejection reason
    - System updates status to "Rejected by Warden"
    - Student and parent notified
    - End
20. If Approve:
    - Warden clicks approve
    - System updates status to "Approved"
    - Student and parent notified
    - Leave granted
    - End

**State Diagram: Room Cleaning Status**

**[STATE DIAGRAM DESCRIPTION - To be inserted as image]**

**States:**
1. **Not Started** (Initial state)
   - No items checked
   - Submit button disabled

2. **In Progress**
   - One or more items checked
   - Not all items checked
   - Submit button disabled

3. **Ready for Submission**
   - All items checked
   - Submit button enabled

4. **Submitted**
   - Student submitted for verification
   - Awaiting warden review
   - Cannot modify checklist

5. **Verified** (Final state)
   - Warden approved cleaning
   - Cleaning cycle complete

6. **Rejected**
   - Warden rejected cleaning
   - Returns to Not Started
   - Student must clean again

**Transitions:**
- Not Started → In Progress: Student checks first item
- In Progress → In Progress: Student checks/unchecks items (not all checked)
- In Progress → Ready for Submission: Student checks last remaining item
- Ready for Submission → In Progress: Student unchecks any item
- Ready for Submission → Submitted: Student clicks submit
- Submitted → Verified: Warden approves
- Submitted → Rejected: Warden rejects
- Rejected → Not Started: System resets checklist

**Component Diagram:**

**[COMPONENT DIAGRAM DESCRIPTION - To be inserted as image]**

**Components:**

**UI Components:**
- Views Package (all screen implementations)
- Widgets Package (reusable UI components)
- Themes Package (styling and theming)

**Business Logic Components:**
- Services Package (business logic)
- Controllers Package (UI controllers)
- Providers Package (state management)

**Data Components:**
- Models Package (data structures)
- Storage Package (persistence)
- Repositories Package (data access)

**Core Components:**
- Lifecycle Package (app lifecycle)
- Localization Package (i18n)
- Constants Package (app constants)
- Utils Package (utilities)

**External Components:**
- Flutter SDK
- Hive Database
- Secure Storage
- Platform Services

**Dependencies:**
- UI Components depend on Business Logic Components
- Business Logic Components depend on Data Components
- All components depend on Core Components
- Data Components depend on External Components

**Deployment Diagram:**

**[DEPLOYMENT DIAGRAM DESCRIPTION - To be inserted as image]**

**Nodes:**

**Mobile Device (Android/iOS)**
- Contains: Application Package (.apk / .ipa)
- Components:
  - Flutter Runtime
  - Dart VM
  - Application Code
  - Hive Database Files
  - Secure Storage (Keychain/Keystore)
  - Local File System

**Development Environment**
- Contains: Source Code, Build Tools
- Components:
  - Flutter SDK
  - Dart SDK
  - Android Studio / Xcode
  - Git Repository

**Build Pipeline**
- Contains: CI/CD Tools
- Components:
  - Flutter Build System
  - Code Signing
  - App Store Deployment

**Connections:**
- Development Environment → Build Pipeline (code push)
- Build Pipeline → App Stores (app deployment)
- App Stores → Mobile Devices (app installation)
- Mobile Devices ↔ Platform Services (notifications, file access)

This comprehensive system design provides a clear blueprint for implementation, ensuring all team members understand the architecture and component interactions.
