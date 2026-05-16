# Resistance.chat

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Website](https://img.shields.io/badge/Website-resistance.chat-red)](https://resistance.chat)

**Decentralized Coordination for the Modern Movement.**

[Resistance.chat](https://resistance.chat) is a free, open-source **secure coordination engine** designed to empower social actions while protecting participant anonymity. By leveraging the decentralized Matrix protocol and end-to-end encryption, we provide a resilient platform for organizing events, sharing field data, and communicating without fear of centralized surveillance.

## 🚀 Overview

Resistance provides a geospatial and communication-centric interface for activists and community organizers. It treats every protest action as a sovereign entity with its own encrypted workspace, ensuring that metadata leakage is minimized and coordination remains private.

### Key Features

- **Encrypted Map Layer:** Visualize protest actions globally. Every map point is a decentralized Matrix state event, encrypted and resilient to takedowns.
- **Secure Comms:** Dedicated, E2EE chat rooms for every event using Olm/Megolm ratchets.
- **Privacy-First Location:** Search for actions via ZIP code or manual map placement. GPS usage is strictly on-demand and never tracked.
- **Anonymous Entry:** Support for guest sessions allows immediate participation without formal registration, lowering the barrier to entry for new supporters.
- **Authenticated Media:** Securely share field images and evidence within the strict security constraints of Matrix's authenticated media standards.
- **Cross-Platform Reach:** Available as a native app for mobile and desktop, and as a Progressive Web App (PWA) for instant, censorship-resistant access.

## 🛠️ Technology Stack

- **Framework:** **Flutter** for a high-performance, single-codebase experience across Android, iOS, Windows, macOS, and Web.
- **Protocol:** **Matrix** for decentralized, end-to-end encrypted identity and messaging.
- **Encryption:** **Vodozemac** (Rust-based) for hardware-backed cryptographic security.
- **Maps:** **OpenStreetMap** via `flutter_map` for privacy-respecting tiles and Windows compatibility.
- **Database:** **SQLite** (`sqflite`) for high-performance local persistence and offline-first functionality.
- **Deployment:** **Cloudflare Tunnels** for a secure, Zero Trust architecture with no public inbound ports.

## 📖 Documentation

- **[Presentation & Rationale](docs/PRESENTATION.md):** Detailed breakdown of architectural decisions, challenges overcome, and future directions.
- **[Design Document](docs/DESIGN.md):** Core system architecture, data models, and protocol implementation details.
- **[Prototype Specs](docs/03-PROTOTYPE.md):** Overview of the current implementation state and features.
- **[Testing Strategy](docs/04-TESTING.md):** Verification procedures for cryptographic state transitions and UI integrity.

## 🚀 Getting Started

### Web Application (PWA)
Access the movement instantly at [resistance.chat](https://resistance.chat).

### Native Installation
Download the latest builds for Android and Desktop from the releases page. 
*Note: For Android, use the provided `push_apk.ps1` script for easy ADB installation.*

```powershell
# From the resistance directory
.\push_apk.ps1
```

## 🤝 Contributing

Resistance is a community-driven project. We welcome security audits, bug reports, and code contributions from anyone dedicated to democratic coordination and privacy.

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/SecurityHardening`).
3. Commit your changes using professional, technical descriptions.
4. Push to the branch.
5. Open a Pull Request.

## ⚖️ License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

*Resistance.chat is a sovereign project dedicated to privacy, decentralization, and the right to organize.*
