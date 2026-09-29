\# CatchEvent — Campus Event Management App



\## 1. Project Overview



CatchEvent is a small Flutter mobile application for discovering and managing campus events.



The goal of the project is to provide students with a simple way to:



\* Discover campus events

\* Search for events

\* Filter events by category

\* View event details

\* Save events

\* Register for events

\* View their saved and registered events



Event organizers can:



\* Create events

\* Edit events

\* Delete events

\* View their events

\* View students registered for their events



The application will use Firebase as the backend.



This is a \*\*small academic project\*\*, so keep the implementation simple and avoid unnecessary advanced features.



\---



\# 2. Technology Stack



\## Frontend



\* Flutter

\* Dart

\* Material 3



\## Backend



\* Firebase Authentication

\* Cloud Firestore

\* Firebase Storage



\## State Management



Use \*\*Provider\*\* for state management.



Do not introduce unnecessary architecture or state-management libraries.



\---



\# 3. User Roles



There are two main user roles.



\## Student



Students can:



\* Register an account

\* Log in

\* Browse events

\* Search events

\* Filter events by category

\* View event details

\* Save/unsave events

\* Register/unregister for events

\* View saved events

\* View registered events

\* View their profile



\## Organizer



Organizers can:



\* Register/login

\* Create events

\* Edit their events

\* Delete their events

\* View their events

\* View students registered for their events



For simplicity, the role can be stored in the user's Firestore document.



Example:



```text

role: "student"

```



or



```text

role: "organizer"

```



\---



\# 4. Core Features



\## 4.1 Authentication



Use Firebase Authentication.



Required functionality:



\* Sign up

\* Login

\* Logout

\* Basic validation



Registration fields:



```text

Name

Email

Password

Role

```



The user selects:



```text

Student

Organizer

```



After login, redirect the user based on their role.



\---



\# 5. Student Features



\## 5.1 Home Screen



The student home screen should display upcoming events.



It should contain:



\* App name

\* Search bar

\* Category filters

\* Event cards

\* Bottom navigation



Example navigation:



```text

Home

Saved

My Events

Profile

```



\---



\## 5.2 Event Search



Students should be able to search events by title.



Example:



```text

Search: Flutter

```



Results:



```text

Flutter Workshop

Advanced Flutter Workshop

Flutter Study Group

```



Search should be case-insensitive.



Search should update the displayed events as the user types.



\---



\## 5.3 Event Filtering



Students should be able to filter events by category.



Initial categories:



```text

Technology

Academic

Sports

Career

Workshop

Social

Club

Other

```



A simple horizontal list of category chips can be used.



Example:



```text

All | Technology | Academic | Sports | Career

```



Selecting `All` displays every event.



\---



\# 6. Event Card



Create a reusable `EventCard` widget.



Each event card should display:



\* Event image

\* Event title

\* Category

\* Date

\* Location

\* Save button



Example:



```text

┌────────────────────────────┐

│                            │

│        Event Image         │

│                            │

├────────────────────────────┤

│ Flutter Workshop        ♡  │

│ Technology                 │

│ 📅 Oct 15                  │

│ 📍 Computer Science Lab   │

└────────────────────────────┘

```



The save button should change between:



```text

♡

```



and



```text

♥

```



depending on whether the current user has saved the event.



\---



\# 7. Event Details



When a student taps an event card, open the event details screen.



Display:



\* Event image

\* Title

\* Description

\* Category

\* Date

\* Start time

\* End time

\* Location

\* Organizer

\* Maximum capacity

\* Number of registered students

\* Save button

\* Register button



Example:



```text

Flutter Workshop



Technology



October 15, 2026

2:00 PM - 5:00 PM



Computer Science Lab



Learn the fundamentals of Flutter

and mobile application development.



Registered: 24 / 50



\[ Register ]

```



If the user has already registered:



```text

\[ Registered ]

```



The button should allow the user to unregister.



\---



\# 8. Save Events



Students can save events they are interested in.



Saving an event should not register the student.



For example:



```text

Saved Event

&#x20;   ≠

Registered Event

```



Students should have a Saved screen containing all saved events.



They should be able to remove events from the Saved screen.



\---



\# 9. Registration



Students can register for events.



Before registering:



```text

\[ Register ]

```



After registering:



```text

\[ Registered ]

```



The system must prevent:



\* Duplicate registration

\* Registration when the event is full



If an event is full:



```text

Event Full

```



The student cannot register.



\---



\# 10. My Events



Create a `My Events` screen showing events the current student has registered for.



Example:



```text

My Events



Upcoming



Flutter Workshop

Oct 15

Computer Science Lab



AI Seminar

Oct 20

Main Hall

```



Students can open an event and unregister.



\---



\# 11. Organizer Features



Organizers should have a simple dashboard.



Navigation:



```text

My Events

Create Event

Profile

```



\---



\## 11.1 Organizer Event List



Show events created by the currently logged-in organizer.



Each event should have:



```text

Edit

Delete

View Registrations

```



\---



\# 12. Create Event



Organizers should be able to create an event with:



```text

Title

Description

Category

Date

Start Time

End Time

Location

Maximum Participants

Event Image

```



Required fields should be validated.



The event image should be uploaded to Firebase Storage.



After successfully creating the event, save the event information in Firestore.



\---



\# 13. Edit Event



Organizers can edit events they created.



They should be able to change:



\* Title

\* Description

\* Category

\* Date

\* Time

\* Location

\* Maximum capacity

\* Image



Only the organizer who created an event should be allowed to edit it.



\---



\# 14. Delete Event



Organizers can delete their own events.



Before deleting, show a confirmation dialog:



```text

Delete Event?



Are you sure you want to delete this event?



\[Cancel] \[Delete]

```



\---



\# 15. View Registrations



An organizer can open one of their events and see registered students.



Example:



```text

Flutter Workshop



24 / 50 Registered



Registered Students



John Doe

john@example.com



Jane Smith

jane@example.com



Alex Brown

alex@example.com

```



\---



\# 16. Firebase Structure



Use Cloud Firestore.



\## Users Collection



```text

users

&#x20;└── userId

&#x20;     ├── name

&#x20;     ├── email

&#x20;     ├── role

&#x20;     └── createdAt

```



Example:



```json

{

&#x20; "name": "John Doe",

&#x20; "email": "john@example.com",

&#x20; "role": "student",

&#x20; "createdAt": "timestamp"

}

```



\---



\## Events Collection



```text

events

&#x20;└── eventId

&#x20;     ├── title

&#x20;     ├── description

&#x20;     ├── category

&#x20;     ├── imageUrl

&#x20;     ├── organizerId

&#x20;     ├── organizerName

&#x20;     ├── date

&#x20;     ├── startTime

&#x20;     ├── endTime

&#x20;     ├── location

&#x20;     ├── capacity

&#x20;     ├── createdAt

```



Example:



```json

{

&#x20; "title": "Flutter Workshop",

&#x20; "description": "Learn the fundamentals of Flutter.",

&#x20; "category": "Technology",

&#x20; "imageUrl": "...",

&#x20; "organizerId": "abc123",

&#x20; "organizerName": "Computer Science Club",

&#x20; "date": "2026-10-15",

&#x20; "startTime": "14:00",

&#x20; "endTime": "17:00",

&#x20; "location": "Computer Science Lab",

&#x20; "capacity": 50,

&#x20; "createdAt": "timestamp"

}

```



\---



\## Registrations Collection



Use a separate collection.



```text

registrations

&#x20;└── registrationId

&#x20;     ├── eventId

&#x20;     ├── studentId

&#x20;     ├── studentName

&#x20;     ├── studentEmail

&#x20;     └── registeredAt

```



\---



\## Saved Events



Use a separate collection:



```text

savedEvents

&#x20;└── savedEventId

&#x20;     ├── eventId

&#x20;     ├── userId

&#x20;     └── savedAt

```



This makes querying saved events simple.



\---



\# 17. Flutter Project Structure



Use the following structure:



```text

lib/

│

├── main.dart

│

├── models/

│   ├── user\_model.dart

│   ├── event\_model.dart

│   └── registration\_model.dart

│

├── services/

│   ├── auth\_service.dart

│   ├── event\_service.dart

│   ├── registration\_service.dart

│   └── storage\_service.dart

│

├── providers/

│   ├── auth\_provider.dart

│   ├── event\_provider.dart

│   └── registration\_provider.dart

│

├── screens/

│   │

│   ├── auth/

│   │   ├── login\_screen.dart

│   │   └── register\_screen.dart

│   │

│   ├── student/

│   │   ├── student\_home\_screen.dart

│   │   ├── event\_details\_screen.dart

│   │   ├── saved\_events\_screen.dart

│   │   ├── my\_events\_screen.dart

│   │   └── student\_profile\_screen.dart

│   │

│   └── organizer/

│       ├── organizer\_home\_screen.dart

│       ├── create\_event\_screen.dart

│       ├── edit\_event\_screen.dart

│       └── registrations\_screen.dart

│

├── widgets/

│   ├── event\_card.dart

│   ├── category\_chip.dart

│   ├── custom\_button.dart

│   └── custom\_text\_field.dart

│

└── utils/

&#x20;   ├── constants.dart

&#x20;   └── validators.dart

```



\---



\# 18. Application Flow



\## Authentication



```text

Splash

&#x20; │

&#x20; ▼

Check Authentication

&#x20; │

&#x20; ├── Not logged in

&#x20; │       ↓

&#x20; │     Login

&#x20; │       ↓

&#x20; │     Register

&#x20; │

&#x20; └── Logged in

&#x20;         │

&#x20;         ▼

&#x20;     Check Role

&#x20;      /       \\

&#x20;     /         \\

&#x20;Student       Organizer

&#x20;   ↓              ↓

&#x20;Student       Organizer

&#x20;  Home           Home

```



\---



\# 19. Student Navigation



Use a bottom navigation bar:



```text

Home

Saved

My Events

Profile

```



\---



\# 20. Organizer Navigation



Use a bottom navigation bar:



```text

My Events

Create Event

Profile

```



\---



\# 21. UI Requirements



Keep the UI modern but simple.



Use:



\* Material 3

\* Cards

\* Rounded corners

\* Consistent spacing

\* Clear typography

\* Event images

\* Bottom navigation

\* Floating action button where appropriate



Do not spend excessive time creating complicated animations.



Focus on functionality.



\---



\# 22. Important Rules



1\. A student cannot register for the same event twice.

2\. A student cannot register if the event is full.

3\. A student can save an event without registering.

4\. A student can unregister from an event.

5\. An organizer can only edit their own events.

6\. An organizer can only delete their own events.

7\. Event creation requires all required fields.

8\. Users must be authenticated to use the application.

9\. Search should be case-insensitive.

10\. Event lists should update when Firestore data changes.



\---



\# 23. Out of Scope



Do NOT implement these features unless there is extra time:



\* Chat

\* Payments

\* QR attendance

\* Push notifications

\* AI recommendations

\* Complex analytics

\* Social media feed

\* Ticket purchasing

\* Maps

\* Admin dashboard

\* Event comments

\* Ratings/reviews



The goal is to keep the project small and functional.



\---



\# 24. Development Order



Build the application in this order:



\### Step 1



Create the Flutter project.



\### Step 2



Configure Firebase.



\### Step 3



Implement authentication.



\### Step 4



Create User model and role-based navigation.



\### Step 5



Create Event model.



\### Step 6



Implement organizer event creation.



\### Step 7



Implement event editing/deleting.



\### Step 8



Implement student event browsing.



\### Step 9



Implement event details.



\### Step 10



Implement search.



\### Step 11



Implement category filtering.



\### Step 12



Implement saving/unsaving events.



\### Step 13



Implement event registration.



\### Step 14



Implement My Events.



\### Step 15



Implement organizer registration list.



\### Step 16



Polish UI and test the complete application.



\---



\# 25. Agent Instructions



You are developing a Flutter + Firebase academic project.



Follow these rules:



\* Keep the implementation simple.

\* Do not add features that are not specified in this document.

\* Use Provider for state management.

\* Use Firebase Authentication for authentication.

\* Use Cloud Firestore for application data.

\* Use Firebase Storage for event images.

\* Keep widgets reusable.

\* Keep Firebase logic inside service classes.

\* Do not put large amounts of Firebase logic directly inside UI widgets.

\* Use models for Firestore data.

\* Validate forms.

\* Handle loading and error states.

\* Do not hardcode event data once Firestore is configured.

\* Follow the project folder structure in this document.

\* Build and test each feature before moving to the next feature.

\* Do not generate the entire application in one step.

\* Work incrementally and explain what was changed after each major step.



Start by setting up the Flutter project and Firebase integration. Then implement authentication before moving to event functionality.



