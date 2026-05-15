# Resistance Project Mandates

This document defines the architectural standards, coding conventions, and operational rules for the Resistance project based on the official Software Design Document.

## Core Architecture
- **Framework:** Flutter (Material 3) with an "offline-first" approach.
- **Protocol:** Matrix (via `matrix` and `flutter_vodozemac` for E2EE).
- **Security:** 
    - **End-to-End Encryption (E2EE):** Mandatory Olm/Megolm ratchets for all rooms.
- **Data Strategy:**
    - **Protest Events:** Managed as persistent Matrix state events (`chat.resistance.protest_event`).
    - **Local Persistence:** Use SQLite (`sqflite`) for immediate UI rendering and offline access.
    - **Push Notifications:** Firebase Cloud Messaging (FCM) acts as a "wake-up" ping for the Matrix `/sync` process; do not send sensitive data via FCM.
- **Infrastructure:** Dockerized Synapse homeserver exposed via Cloudflare Tunnels (TLS 1.3).

## Coding Standards
- **Theme:** High-contrast "Resistance Red" (`Color(0xFFB71C1C)`) and Dark/White theme.
- **UI Consistency:**
    - Persistent bottom navigation: Map, Events, Chat.
    - Use `showModalBottomSheet` for event metadata.
    - Mandatory visual indicators for E2EE status (Lock icon) and cryptographic verification.
- **Service Layer:** All Matrix logic must be encapsulated in `MatrixService`.

## Operational Rules
- **Privacy:** Minimize metadata leakage; E2EE is the default for all communications.
- **Testing:** Verify cryptographic state transitions (device verification, cross-signing).
- **Dependencies:** `flutter_vodozemac` for encryption, `flutter_map` for geospatial visualization.
