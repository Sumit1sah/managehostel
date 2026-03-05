# CHAPTER 3: PROBLEM STATEMENT AND REQUIREMENT SPECIFICATION

## 3.1 Project Planning

Effective project planning is essential for successful software development. The Hostel Management System project followed a structured planning approach encompassing timeline definition, resource allocation, risk assessment, and milestone identification.

**Project Timeline:**

The project was executed over a period of 6 months (October 2025 - March 2026) divided into distinct phases:

**Phase 1: Requirement Analysis and Design (4 weeks)**
- Stakeholder interviews with students, parents, and hostel administrators
- Requirement gathering and documentation
- Feasibility study and technology selection
- System architecture design
- Database schema design
- UI/UX wireframing and prototyping
- Project plan finalization

**Phase 2: Development Setup and Core Implementation (6 weeks)**
- Development environment setup
- Project structure creation
- Core architecture implementation
- Database integration and encryption setup
- Authentication system development
- State management implementation
- Basic UI framework development

**Phase 3: Feature Development (8 weeks)**
- Student module implementation
  - Dashboard and navigation
  - Room cleaning management
  - Washing machine queue system
  - Leave application module
  - Complaint management
- Parent module implementation
  - Parent authentication
  - Dashboard and monitoring
  - Leave approval workflow
  - Communication channel
- Warden module implementation
  - Administrative dashboard
  - User management
  - Approval workflows
  - Report generation

**Phase 4: Testing and Quality Assurance (3 weeks)**
- Unit testing of core logic
- Widget testing of UI components
- Integration testing of complete workflows
- Security testing and vulnerability assessment
- Performance testing and optimization
- User acceptance testing with pilot group
- Bug fixing and refinement

**Phase 5: Documentation and Deployment (3 weeks)**
- Technical documentation
- User manual creation
- API documentation
- Deployment preparation
- App store submission preparation
- Final testing and validation
- Project report writing

**Resource Allocation:**

**Human Resources:**
- 4 team members with defined roles and responsibilities
- Project guide for mentorship and technical guidance
- Test users from hostel community for validation

**Technical Resources:**
- Development machines (laptops with adequate specifications)
- Android and iOS devices for testing
- Development tools (Android Studio, VS Code, Xcode)
- Version control system (Git/GitHub)
- Project management tools (Trello/Jira)
- Documentation tools (Google Docs, Markdown editors)

**Software Resources:**
- Flutter SDK 3.0+
- Dart programming language
- Required packages and dependencies
- Testing frameworks
- Design tools (Figma for UI mockups)

**Risk Assessment and Mitigation:**

**Technical Risks:**

Risk: Learning curve for Flutter and Dart
Mitigation: Allocated initial weeks for team training, utilized online resources and documentation

Risk: Encryption implementation complexity
Mitigation: Used well-tested libraries (Hive, flutter_secure_storage), conducted security reviews

Risk: State management complexity
Mitigation: Selected Provider pattern for simplicity, followed official documentation

Risk: Cross-platform compatibility issues
Mitigation: Regular testing on both Android and iOS, followed platform-specific guidelines

**Schedule Risks:**

Risk: Feature creep and scope expansion
Mitigation: Clearly defined scope, prioritized features, maintained feature backlog for future

Risk: Delays in development phases
Mitigation: Built buffer time into schedule, regular progress reviews, agile approach allowing adjustments

**Resource Risks:**

Risk: Team member unavailability
Mitigation: Cross-training on modules, documentation of work, regular knowledge sharing

Risk: Device availability for testing
Mitigation: Utilized emulators, borrowed devices from peers, tested on available devices first

**Methodology:**

The project followed an Agile development methodology with iterative development cycles:

**Sprint Planning:** Two-week sprints with defined goals and deliverables
**Daily Standups:** Brief team meetings to discuss progress and blockers
**Sprint Reviews:** Demonstrations of completed features to guide
**Sprint Retrospectives:** Team reflection on process improvements
**Continuous Integration:** Regular code integration and testing

**Milestones:**

1. Project kickoff and requirement finalization (Week 2)
2. Architecture design approval (Week 4)
3. Core framework completion (Week 8)
4. Student module completion (Week 12)
5. Parent and warden modules completion (Week 16)
6. Testing completion (Week 20)
7. Documentation completion (Week 22)
8. Project submission (Week 24)

This structured planning approach ensured systematic progress, early identification of issues, and successful project completion within the academic timeframe.

## 3.2 Project Analysis

### 3.2.1 Software Requirements Specification (SRS)

**Purpose:**

This Software Requirements Specification document provides a complete description of the Hostel Management System. It details functional and non-functional requirements, system interfaces, and constraints that guide development and serve as a contract between stakeholders and developers.

**Scope:**

The Hostel Management System is a mobile application designed to digitize and automate hostel operations for educational institutions. The system serves three user categories: students, parents, and hostel wardens, providing role-specific functionalities for efficient hostel administration.

**Definitions, Acronyms, and Abbreviations:**

- **HMS:** Hostel Management System
- **UI:** User Interface
- **UX:** User Experience
- **API:** Application Programming Interface
- **CRUD:** Create, Read, Update, Delete
- **SRS:** Software Requirements Specification
- **AES:** Advanced Encryption Standard
- **NoSQL:** Not Only SQL
- **ACID:** Atomicity, Consistency, Isolation, Durability
- **JWT:** JSON Web Token (for future cloud integration)
- **RBAC:** Role-Based Access Control

**Overall Description:**

**Product Perspective:**

The Hostel Management System is a standalone mobile application that operates independently without requiring backend server infrastructure in its current implementation. The system is designed with architecture supporting future cloud integration for multi-hostel deployments and real-time synchronization.

**Product Functions:**

The system provides the following major functions:
- User authentication and authorization
- Room allocation and management
- Cleaning verification and tracking
- Washing machine queue management
- Leave application and approval workflow
- Complaint registration and resolution
- Announcement broadcasting
- Parent-student-warden communication
- Report generation and data export
- Multi-language support
- Theme customization

**User Characteristics:**

**Students:** Primary users, aged 18-25, tech-savvy, use smartphones daily. Require intuitive interface with minimal learning curve.

**Parents:** Secondary users, aged 40-60, varying technical proficiency. Require simple, clear interface with essential information prominently displayed.

**Wardens:** Administrative users, aged 30-55, moderate technical skills. Require efficient tools for managing multiple students and operations.

**Constraints:**

- Must work offline without internet connectivity
- Must support Android 5.0+ and iOS 11.0+
- Must encrypt all sensitive data
- Must complete operations within 2 seconds for responsive UX
- Must minimize battery consumption
- Must occupy less than 100MB storage
- Must follow platform-specific design guidelines

**Assumptions and Dependencies:**

- Users have smartphones with camera capability
- Devices have minimum 2GB RAM
- Users grant necessary permissions (storage, camera)
- Platform keystores are available for secure storage
- Devices have sufficient storage space

### 3.2.2 Functional Requirements

Functional requirements specify what the system must do—the features, capabilities, and functions that must be implemented.

**FR1: User Authentication**

FR1.1: System shall provide secure login functionality with user ID and password
FR1.2: System shall encrypt and store credentials in platform keystore
FR1.3: System shall maintain user session across app restarts
FR1.4: System shall provide logout functionality clearing all secure data
FR1.5: System shall support three user roles: Student, Parent, Warden
FR1.6: System shall validate credentials against locally stored user database
FR1.7: System shall provide password change functionality
FR1.8: System shall implement automatic session timeout after 30 days of inactivity

**FR2: Student Dashboard**

FR2.1: System shall display personalized dashboard with student information
FR2.2: System shall provide quick access to frequently used features
FR2.3: System shall display recent announcements and notifications
FR2.4: System shall show current room and floor information
FR2.5: System shall display pending actions (leave applications, complaints)
FR2.6: System shall provide navigation to all student features

**FR3: Room Cleaning Management**

FR3.1: System shall allow students to view their assigned room cleaning status
FR3.2: System shall provide three-point checklist (bathroom, room, toilet)
FR3.3: System shall allow marking checklist items as complete
FR3.4: System shall enable submission for verification only when all items checked
FR3.5: System shall track cleaning status (Pending, In Progress, Completed, Verified)
FR3.6: System shall allow wardens to verify and approve cleaning
FR3.7: System shall maintain history of cleaning records with timestamps
FR3.8: System shall support floor-wise organization of rooms

**FR4: Washing Machine Queue Management**

FR4.1: System shall display available washing machines with current status
FR4.2: System shall allow students to join queue for selected machine
FR4.3: System shall display real-time queue position and estimated wait time
FR4.4: System shall automatically progress queue when cycle completes
FR4.5: System shall notify students when their turn arrives
FR4.6: System shall allow students to leave queue
FR4.7: System shall prevent duplicate queue entries for same student
FR4.8: System shall track queue history for analytics

**FR5: Room Availability**

FR5.1: System shall display floor-wise room organization
FR5.2: System shall show bed-level availability status
FR5.3: System shall indicate occupied and available beds
FR5.4: System shall display current occupants for occupied beds
FR5.5: System shall update availability in real-time as allocations change
FR5.6: System shall support dynamic floor addition by wardens

**FR6: Leave Application**

FR6.1: System shall allow students to submit leave applications
FR6.2: System shall capture leave type, dates, and reason
FR6.3: System shall route applications to parent for approval
FR6.4: System shall route parent-approved applications to warden
FR6.5: System shall track application status (Pending, Approved, Rejected)
FR6.6: System shall notify applicant of status changes
FR6.7: System shall maintain leave history
FR6.8: System shall allow parents to approve/reject applications with comments

**FR7: Complaint Management**

FR7.1: System shall allow students to register complaints/issues
FR7.2: System shall categorize complaints (maintenance, food, cleanliness, etc.)
FR7.3: System shall allow attaching photos to complaints
FR7.4: System shall assign unique ID to each complaint
FR7.5: System shall track complaint status (Open, In Progress, Resolved, Closed)
FR7.6: System shall allow wardens to update complaint status
FR7.7: System shall notify students of status updates
FR7.8: System shall maintain complaint history

**FR8: Announcements**

FR8.1: System shall allow wardens to create and broadcast announcements
FR8.2: System shall categorize announcements (general, urgent, event, etc.)
FR8.3: System shall display announcements to all users
FR8.4: System shall highlight urgent announcements
FR8.5: System shall maintain announcement history
FR8.6: System shall support rich text formatting in announcements
FR8.7: System shall allow targeting announcements to specific floors/rooms

**FR9: Parent Portal**

FR9.1: System shall provide separate parent login linked to student ID
FR9.2: System shall display parent dashboard with ward information
FR9.3: System shall show ward's room, floor, and hostel details
FR9.4: System shall display pending leave applications for approval
FR9.5: System shall allow communication with warden
FR9.6: System shall show announcements relevant to parents
FR9.7: System shall display ward's complaint history

**FR10: Warden Administration**

FR10.1: System shall provide administrative dashboard with statistics
FR10.2: System shall allow user management (add, edit, delete students)
FR10.3: System shall enable room allocation and swapping
FR10.4: System shall require password verification for critical operations
FR10.5: System shall provide leave approval workflow
FR10.6: System shall enable complaint management and resolution
FR10.7: System shall allow announcement creation and management
FR10.8: System shall provide data export functionality (PDF, CSV)
FR10.9: System shall display analytics and usage statistics

**FR11: Settings and Preferences**

FR11.1: System shall allow theme selection (light, dark, system)
FR11.2: System shall support multiple languages with dynamic switching
FR11.3: System shall allow profile photo upload and management
FR11.4: System shall provide notification preferences
FR11.5: System shall allow password change
FR11.6: System shall persist all settings across app restarts

**FR12: Data Management**

FR12.1: System shall automatically save all data changes
FR12.2: System shall implement debounced writes (500ms delay)
FR12.3: System shall force save on app pause/background
FR12.4: System shall restore complete application state on restart
FR12.5: System shall encrypt all sensitive data with AES-256
FR12.6: System shall store encryption key in platform keystore
FR12.7: System shall provide data export functionality
FR12.8: System shall implement data validation and sanitization

### 3.2.3 Non-Functional Requirements

Non-functional requirements specify how the system should perform—quality attributes, constraints, and standards.

**NFR1: Performance Requirements**

NFR1.1: System shall respond to user actions within 2 seconds
NFR1.2: System shall load screens within 1 second
NFR1.3: System shall complete database operations within 500ms
NFR1.4: System shall support minimum 1000 concurrent users per hostel
NFR1.5: System shall handle databases up to 100MB without performance degradation
NFR1.6: System shall maintain smooth 60fps UI rendering
NFR1.7: System shall minimize battery consumption (< 5% per hour of active use)

**NFR2: Security Requirements**

NFR2.1: System shall encrypt all data at rest using AES-256
NFR2.2: System shall store credentials in platform-specific secure storage
NFR2.3: System shall implement role-based access control
NFR2.4: System shall validate and sanitize all user inputs
NFR2.5: System shall not log sensitive information
NFR2.6: System shall implement secure session management
NFR2.7: System shall protect against common vulnerabilities (SQL injection, XSS, etc.)
NFR2.8: System shall comply with data protection regulations

**NFR3: Reliability Requirements**

NFR3.1: System shall have 99.9% uptime (excluding device-specific issues)
NFR3.2: System shall gracefully handle errors without crashes
NFR3.3: System shall recover from unexpected termination
NFR3.4: System shall prevent data loss through automatic saving
NFR3.5: System shall maintain data integrity across operations
NFR3.6: System shall provide meaningful error messages

**NFR4: Usability Requirements**

NFR4.1: System shall follow platform-specific design guidelines (Material Design for Android, Cupertino for iOS)
NFR4.2: System shall provide intuitive navigation requiring minimal training
NFR4.3: System shall support accessibility features (screen readers, high contrast)
NFR4.4: System shall provide helpful error messages and guidance
NFR4.5: System shall maintain consistent UI/UX across all screens
NFR4.6: System shall support multiple languages for diverse users
NFR4.7: System shall achieve usability score > 80% in user testing

**NFR5: Maintainability Requirements**

NFR5.1: System shall follow modular architecture for easy maintenance
NFR5.2: System shall maintain comprehensive code documentation
NFR5.3: System shall follow coding standards and best practices
NFR5.4: System shall achieve > 80% code coverage in tests
NFR5.5: System shall use version control for all code
NFR5.6: System shall separate concerns (UI, business logic, data)

**NFR6: Portability Requirements**

NFR6.1: System shall support Android 5.0 (API 21) and above
NFR6.2: System shall support iOS 11.0 and above
NFR6.3: System shall function consistently across different screen sizes
NFR6.4: System shall adapt to different device orientations
NFR6.5: System shall work on devices with varying hardware capabilities

**NFR7: Scalability Requirements**

NFR7.1: System shall support up to 1000 students per hostel instance
NFR7.2: System shall handle up to 50 rooms per floor
NFR7.3: System shall support up to 10 washing machines
NFR7.4: System shall maintain performance with growing data volume
NFR7.5: System architecture shall support future cloud integration

**NFR8: Availability Requirements**

NFR8.1: System shall function completely offline
NFR8.2: System shall not require internet connectivity for core features
NFR8.3: System shall be available 24/7 on user devices
NFR8.4: System shall handle device restarts gracefully

**NFR9: Compliance Requirements**

NFR9.1: System shall comply with data protection regulations
NFR9.2: System shall follow mobile app store guidelines
NFR9.3: System shall implement privacy-by-design principles
NFR9.4: System shall provide privacy policy and terms of service
NFR9.5: System shall obtain necessary user permissions

**NFR10: Documentation Requirements**

NFR10.1: System shall include comprehensive user manual
NFR10.2: System shall provide technical documentation for developers
NFR10.3: System shall document all APIs and interfaces
NFR10.4: System shall include installation and deployment guide
NFR10.5: System shall maintain updated README and changelog

## 3.3 System Design

### 3.3.1 Design Constraints

Design constraints are limitations and restrictions that influence system design decisions. Understanding these constraints ensures realistic design within project boundaries.

**Technical Constraints:**

**Platform Constraints:**
- Must support Android and iOS with single codebase
- Must adhere to platform-specific design guidelines
- Must work within mobile device resource limitations (CPU, memory, battery)
- Must comply with app store requirements and policies

**Storage Constraints:**
- Limited device storage capacity (must optimize data storage)
- Must minimize app size for easy download and installation
- Must manage storage efficiently as data grows

**Performance Constraints:**
- Must maintain responsive UI on low-end devices
- Must minimize battery consumption
- Must operate efficiently with limited RAM
- Must handle concurrent operations without blocking UI

**Security Constraints:**
- Must encrypt sensitive data without significant performance impact
- Must use platform-provided security mechanisms
- Must not store sensitive data in logs or temporary files
- Must implement secure authentication without backend server

**Development Constraints:**

**Time Constraints:**
- Must complete within 6-month academic project timeline
- Must allocate time for learning new technologies
- Must balance feature development with testing and documentation

**Resource Constraints:**
- Limited team size (4 members)
- Limited access to diverse testing devices
- No budget for paid services or tools
- Reliance on open-source libraries and frameworks

**Skill Constraints:**
- Team learning Flutter and Dart during development
- Limited prior experience with mobile app development
- Need to acquire knowledge of encryption and security

**Operational Constraints:**

**Offline Operation:**
- Must function without network connectivity
- Must store all data locally
- Must handle synchronization conflicts (for future cloud integration)

**User Environment:**
- Users may have varying levels of technical proficiency
- Devices may have different screen sizes and resolutions
- Users may be in areas with poor lighting (affects camera features)

**Regulatory Constraints:**

**Privacy Regulations:**
- Must comply with data protection laws
- Must obtain user consent for data collection
- Must provide data deletion capabilities
- Must implement privacy-by-design principles

**Accessibility Requirements:**
- Must support accessibility features for users with disabilities
- Must provide alternative text for images
- Must ensure sufficient color contrast
- Must support screen readers

**Design Decisions Based on Constraints:**

Given these constraints, key design decisions include:
- Flutter framework for cross-platform development with single codebase
- Hive database for efficient local storage with built-in encryption
- Provider pattern for simple yet effective state management
- Offline-first architecture eliminating network dependency
- Modular architecture for maintainability within resource constraints
- Material Design for consistent, accessible UI
- Debounced writes for performance optimization

These constraints shaped the system architecture and implementation approach, ensuring a practical, deployable solution within project limitations.
