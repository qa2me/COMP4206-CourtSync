# CourtSync 

CourtSync is a real-time, distributed sports management mobile application built with **Flutter**. Developed for **COMP 4206 (Distributed Computing)**, the platform focuses on synchronizing tournament data and court availability across multiple users in a distributed environment.

## Overview

CourtSync addresses the challenges of resource contention and real-time data consistency. Whether it is managing limited spots in a tournament or booking a physical court, the system ensures that the distributed state is updated across all clients using reactive streams.

## Key Features

- **Real-time Tournament Tracking:** Live updates for tournament status (Upcoming, Ongoing, Completed) and remaining spots.
- **Dynamic Registration:** Users can join tournaments and see their status updated instantly across the network.
- **Quick Match System:** A matchmaking feature designed to connect players for immediate challenges.
- **Court Discovery:** Browse nearby sports facilities with live data fetching.
- **Distributed State Management:** Uses asynchronous streams to ensure the UI stays in sync with the backend database without manual refreshes.

## Technical Architecture

### Tech Stack
- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Communication:** Stream-based real-time data fetching.
- **Backend:** Integrated via `DatabaseService` (supporting Firebase/Firestore logic).

### Core Components
- **Tournament Logic:** Supports various formats including Single/Double Elimination, Round Robin, and Swiss.
- **Concurrency Handling:** Manages `spotsLeft` and `isJoined` states to prevent over-registration in a distributed setting.
- **Service Layer:** Centralized `DatabaseService` to handle `tournamentsStream`, `courtsStream`, and user registrations.

## Project Structure

- `lib/models/`: Data objects for Tournaments and Courts.
- `lib/pages/`: UI screens (Home, View Tournament, Start Match).
- `lib/widgets/`: Reusable UI components like `TournamentCard` and `HeroSection`.
- `lib/services/`: Logic for data persistence and stream management.

## Getting Started

### Prerequisites
- Flutter SDK (`^3.0.0` recommended)
- Dart SDK
- An Android/iOS Emulator or physical device

### Installation
1. **Clone the repository:**
   ```bash
   git clone [https://github.com/qa2me/COMP4206-CourtSync.git](https://github.com/qa2me/COMP4206-CourtSync.git)
