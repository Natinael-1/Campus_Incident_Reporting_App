# Campus Incident Reporting Application

A role-based platform built with **Flutter** and **Google Firebase** (`Firebase Auth`, `Cloud Firestore`, and `Firebase Storage`) that enables ALU students and campus staff to report, track, and resolve campus infrastructure and safety incidents in real time.

## Project Overview

University campuses rely on daily physical infrastructure—classrooms, water systems, electrical grids, safety equipment, and sanitation facilities. Traditional word-of-mouth or paper maintenance logs often cause delayed responses, duplicate reports, and zero status transparency for students.

The **Campus Incident Reporting Application** digitizes the entire campus maintenance lifecycle:

* **Students (`role: "student"`):** Log categorized incidents with structured campus locations and optional camera/gallery photographs, browse and filter the live campus feed, edit or delete their pending reports, and track resolutions via a 3-step **Status Timeline**.
* **Authorized Staff (`role: "staff"`):** Verified against a server-side Cloud Firestore allowlist (`authorized_staff`) using `@alueducation.com` emails, granting access to a dedicated **Staff Operations Portal** to filter incident queues and advance resolutions (`Submitted` → `In Progress` → `Resolved`) in real time.

## Key Features

###  Student Portal
* **Personalized Home Dashboard:** Displays live summary counters (*My Reports*, *In Progress*, *Resolved*, *Submitted*), a quick-action reporting banner, and the 5 most recent campus reports.
* **Multi-Category Incident Reporting (`Create`):** Submit validated reports across 5 infrastructure categories (**Facilities**, **Water**, **Electricity**, **Safety**, **Sanitation**) with a campus location dropdown and optional camera or gallery photo attachment.
* **Real-Time Search & Multi-Criteria Filtering (`Read`):** Search reports by title, description, location, or category, and filter instantaneously using horizontal status and category chips.
* **3-Step Live Status Timeline:** Inspect exact timestamps for `Submitted`, `In Progress`, and `Resolved` stages on the Incident Details screen, including staff updater attribution.
* **Self-Service Report Management (`Update` & `Delete`):** Edit report details (or replace/remove attached photos) and delete personal reports while their status is still `Submitted`.

### Staff Operations Portal
* **Domain-Restricted Role Security (RBAC):** Prevents privilege escalation by verifying `@alueducation.com` accounts against the pre-seeded `authorized_staff` Cloud Firestore collection during registration and sign-in.
* **Interactive Campus Overview Metrics:** View campus-wide totals and tap any summary card (*Total*, *Submitted*, *In Progress*, *Resolved*) to filter the incident queue immediately.
* **One-Tap & Detailed Status Resolution (`Update`):** Advance incidents to `In Progress` or `Resolved` directly from the queue or the Incident Details screen, automatically stamping `inProgressAt`, `resolvedAt`, and `updatedByStaffName` in Cloud Firestore.
* **Administrative CRUD Controls:** Edit or remove duplicate/invalid incident reports across the platform with cascading Firebase Storage image cleanup.

## System Architecture & Tech Stack

The application follows a modular **Four Parts Architecture** to enforce strict separation of concerns:

1. **Presentation(UI) (`lib/screens/` & `lib/widgets/`):** Reactive Light Blue & White Material 3 UI screens and reusable stateless widgets.
2. **State Management (`lib/providers/`):** `AuthProvider` and `IncidentProvider` (`ChangeNotifier` + `Provider`) managing live streams, in-memory filtering, and loading states.
3. **Service (`lib/services/`):** `AuthService`, `FirestoreService`, and `StorageService` encapsulating all Firebase SDK operations and error handling.
4. **Data Model & Utility (`lib/models/` & `lib/utils/`):** Strongly typed models (`UserModel`, `IncidentModel`) with `toMap()`/`fromMap()` serialization, regex validators, and design constants.

| Category | Technology | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Framework** | Flutter & Dart | `3.x` | Cross-platform native mobile UI & sound null safety |
| **State Management** | `provider` | `^6.1.2` | Reactive `ChangeNotifier` state injection & UI rebuilds |
| **Authentication** | `firebase_auth` | `^5.3.1` | Email/password authentication & persistent sessions |
| **Database** | `cloud_firestore` | `^5.4.4` | Real-time NoSQL document persistence & `.snapshots()` |
| **Media Storage** | `firebase_storage` | `^12.3.2` | Photo uploads via Firebase Storage Emulator (`9199`) |
| **Camera / Gallery** | `image_picker` | `^1.1.2` | Native camera capture, gallery picker & compression |

## Project Directory Structure

    lib/
    ├── main.dart                                 
    ├── firebase_options.dart                     
    ├── models/
    │   ├── user_model.dart                       
    │   └── incident_model.dart                   
    ├── utils/
    │   ├── app_constants.dart                    
    │   └── validators.dart                       
    ├── services/
    │   ├── auth_service.dart                     
    │   ├── firestore_service.dart                
    │   └── storage_service.dart                  
    ├── providers/
    │   ├── auth_provider.dart                    
    │   └── incident_provider.dart                
    ├── widgets/
    │   ├── status_badge.dart                     
    │   ├── incident_card.dart                    
    │   └── custom_text_field.dart               
    └── screens/
        ├── auth/
        │   ├── login_screen.dart                 
        │   └── register_screen.dart              
        ├── student/
        │   ├── student_home_screen.dart          
        │   └── create_incident_screen.dart       
        ├── staff/
        │   └── staff_dashboard_screen.dart       
        └── shared/
            └── incident_detail_screen.dart       

## Cloud Firestore Database Schema

* **`users/{uid}`:** Stores registered user profiles (`uid`, `name`, `email`, `role`, `department`, `location`, `createdAt`).
* **`authorized_staff/{email}`:** Server-side allowlist storing pre-approved `@alueducation.com` staff emails (`email`, `department`, `isActive`).
* **`incidents/{incidentId}`:** Stores incident reports (`id`, `title`, `description`, `category`, `location`, `imageUrl`, `status`, `reportedByUid`, `reportedByName`, `updatedByStaffName`, `createdAt`, `updatedAt`, `inProgressAt`, `resolvedAt`).

## Getting Started & Installation

### 1. Prerequisites
* **Flutter SDK** (`>=3.0.0`) and **Dart SDK**
* **Android Studio** (Android Emulator) or a physical Android device
* **Node.js** & **Firebase CLI** (`npm install -g firebase-tools`)
* **Java JDK 11+** (required by the Firebase Emulator Suite)

### 2. Clone the Repository & Install Dependencies

    git clone <YOUR_GITHUB_REPOSITORY_URL>
    cd Campus_Incident_Reporting_App
    flutter pub get

### 3. Start the Firebase Storage Emulator (Terminal Tab 1)
This project uses the official **Firebase Storage Emulator** on port `9199` so incident photo uploads run with zero cloud billing requirements and persist locally inside `./emulator_data`:

    firebase emulators:start --only storage --import=./emulator_data --export-on-exit=./emulator_data

* **Android Emulator Host:** Configured automatically in `lib/main.dart` as `10.0.2.2:9199`.
* **Physical USB Device Note:** If testing on a physical phone over USB, run `adb reverse tcp:9199 tcp:9199` and set `emulatorHost = 'localhost'` in `lib/main.dart`.

### 4. Run the Application (Terminal Tab 2)

    flutter run

## Demo & Testing Credentials (Role-Based Access)

Upon first launch, `AuthService.seedAuthorizedStaff()` automatically seeds the `authorized_staff` allowlist in Cloud Firestore. You can test both roles using the following email patterns:

| Role | Email Address to Register / Sign In | Assigned Access Level |
| :--- | :--- | :--- |
| **Student Account** | Any standard email (e.g., `natinale@alustudent.com`) | Routes to **Student Portal** (`role: "student"`). Cannot alter resolution statuses. |
| **Authorized Staff** | `facilities@alueducation.com`, `security@alueducation.com` | Verified against `authorized_staff`. Routes to **Staff Operations Portal** (`role: "staff"`). |
| **Unauthorized Staff** | Any unlisted `@alueducation.com` email (e.g., `fake@alueducation.com`) | **Blocked** with an Access Denied error message to prevent privilege escalation. |  

## Note  
Credentials(Passwords) for the test account are provided in the COMMENT SECTION of Canvas.


## Author

**Natinael Boda Borana**  
BSc. (Hons) in Software Engineering  
African Leadership University (ALU) — Kigali, Rwanda