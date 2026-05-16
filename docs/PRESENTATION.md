# Resistance App: Development Presentation

## 1. Introduction
The **Resistance** app is a decentralized, secure, and privacy-focused platform designed to coordinate social actions and protest events. Built with Flutter and the Matrix protocol, it prioritizes user anonymity and end-to-end encryption (E2EE) to ensure that coordination remains resilient and private.

---

## 2. Technical Decisions & Rationale

### 2.1 Flutter for Cross-Platform Reach
The decision to use **Flutter** was driven by the need for a truly multi-platform coordination tool. 
- **Universal Availability:** A single codebase allows Resistance to run natively on Android, iOS, macOS, Windows, and Linux.
- **PWA Surprise:** One of the most pleasant surprises during development was the effectiveness of the **Progressive Web App (PWA)** implementation. This allows users to access the movement's tools instantly via a browser without needing to visit an app store—crucial for rapid, censorship-resistant deployment.

### 2.2 OpenStreetMap (OSM) for Privacy & Compatibility
While many apps default to Google Maps, Resistance uses **OpenStreetMap** via `flutter_map`.
- **Privacy:** OSM allows for tile fetching without the aggressive tracking associated with proprietary map providers.
- **Platform Compatibility:** OSM ensures a consistent experience on Windows and desktop platforms where other native map SDKs may have limited support or heavy licensing requirements.

### 2.3 The Matrix Protocol: Universal Encryption
Everything in Resistance is encrypted. By building on the **Matrix Protocol**, we ensured that encryption isn't just an "add-on" for chat, but the foundation of all data:
- **Map Points:** Protest locations are stored as encrypted state events.
- **Communications:** All room chats are protected by Olm/Megolm ratchets.
- **Media:** Uploaded images and evidence are encrypted at rest and in transit, ensuring that only intended recipients can view sensitive field data.

---

## 3. Screen-by-Screen Breakdown

### 2.1 The Map Screen (Geospatial Core)
The Map Screen is the primary entry point of the application. It provides a geospatial visualization of all ongoing and upcoming protest actions.
- **Privacy First:** Users can search for their location via ZIP code rather than sharing precise GPS coordinates, mitigating tracking risks.
- **Real-time Markers:** Protest events are represented by high-contrast markers. Tapping a marker opens an `EventDetailsPanel` via a modal bottom sheet.
- **Implementation:** Built using `flutter_map` with OpenStreetMap tiles.

### 2.2 The Events Screen
This screen provides a centralized list of all scoped protest events, sorted by time and relevance.
- **Discovery:** Users can quickly browse the "what, when, and where" of the movement.
- **Navigation:** Deep links directly from the list to the map or the event's dedicated chat room.

### 2.3 The Chat Screens (Matrix Integration)
The heart of the coordination is the Matrix-powered chat system.
- **Room-Based Coordination:** Each event has a dedicated, E2EE chat room.
- **Guest Access:** To lower the barrier to entry, the app supports anonymous guest sessions, allowing users to read and participate without a formal registration.
- **Authenticated Media:** Full support for image sharing, even within the strict security constraints of Matrix's MSC3916 (Authenticated Media).

### 2.4 Event Creation & Editing
For authenticated users, the app provides tools to organize new actions.
- **Map Picker:** A dedicated utility to precisely place event markers.
- **Matrix State Events:** Events are stored as persistent state events on the Matrix protocol, ensuring they are decentralized and censorship-resistant.

### 2.5 Invite & Scanner System
To facilitate secure growth, the app includes a QR code scanner and display system.
- **Invites:** Generate QR codes that link directly to events or chat rooms.
- **Scanner:** Built-in tool for joining actions on the ground.

---

## 3. Development Journey: Key Milestones

The development of Resistance followed a rapid, iterative path reflected in our commit history:

- **The Foundation (Feb 2026):** Initial repository setup focused on Firebase for hosting and basic data models.
- **The Matrix Pivot:** Realizing the need for sovereign, decentralized communication, we pivoted from Firestore-based chat to the Matrix protocol. This was a significant architectural shift that mandated the use of `MatrixService` for all state management.
- **E2EE Hardening (March 2026):** Implementing `flutter_vodozemac` for hardware-backed encryption.
- **Web Optimization (April - May 2026):** Moving the app to a production-ready Web state, involving complex cache-busting and build automation.

---

## 4. Challenges Overcome

### 4.1 The Authenticated Media Hurdle (MSC3916)
One of the most persistent bugs was image rendering in the chat. Standard Matrix SDK methods often failed to handle authentication tokens correctly when fetching media on the Web. 
- **Solution:** I implemented a custom logic to manually construct media URLs, injecting the `access_token` as a query parameter to ensure compatibility with MSC3916 servers while maintaining security.

### 4.2 Aggressive Web Caching
During deployment to Firebase Hosting, users frequently encountered "The Spinning Circle" (stale code). Browsers were caching `main.dart.js` too aggressively.
- **Solution:** I developed an "Ultimate Cache-Busting" strategy, overriding the `mainJsPath` in the build process to include unique hashes, forcing browsers to always pull the latest version of the app.

### 4.3 Map Controller Lifecycle
In the early versions, navigating quickly between tabs would cause the map to crash or fail to center.
- **Solution:** I refactored the `MapScreen` to include `_isMapReady` checks and safe move wrappers, ensuring that commands are only sent to the `MapController` when it is properly attached to the widget tree.

---

## 5. Future Directions: The Notification Complexity
While basic notification banners are implemented, fully enabling push notifications across the decentralized network remains a complex future goal.

The challenge lies in the sheer scale of the notification problem:
1. **Multi-Room Monitoring:** A single user might be interested in dozens of different events/rooms.
2. **Prioritization:** Distinguishing between a casual chat message and a critical "Action Update" (e.g., location change) requires sophisticated event filtering.
3. **Decentralized Push:** Managing push tokens across multiple homeservers while maintaining privacy is a significant architectural undertaking that will be addressed in v2.0.

### 5.4 Streamlined Authentication Flow
Currently, the application requires users to manually logout of a guest account before they can sign in to a registered account or create a new one.
- **Goal:** Implement an "Upgrade to Account" or "Seamless Sign-in" flow that automatically handles the transition from guest to authenticated status, reducing friction for new users who want to move from anonymous browsing to active coordination.

---
**Author:** Resistance Development Team
**Date:** May 15, 2026
