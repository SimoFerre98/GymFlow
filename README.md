# GymFlow 🏋️‍♂️

**GymFlow** is a dynamic, highly customizable fitness application built with **Flutter** and **Firebase**. It is designed to help users track their workouts, monitor progress, and connect with gym buddies in real-time.

> ⚠️ **Questo README descrive l'intenzione del prodotto, non lo stato del codice.** Alcune funzioni
> elencate sotto sono parziali o non implementate. La fonte di verità su cosa l'app fa davvero è
> [`docs/HANDOFF.md`](docs/HANDOFF.md), e sullo stato di ogni storia
> [`docs/BACKLOG.md`](docs/BACKLOG.md).

## 🚀 Features

- **🔐 Authentication**: Secure User Registration & Login via Firebase Auth.
- **👤 User Profiles**: Personalized profiles with stats (Weight, Height, Streak).
- **🏋️‍♀️ Workout Management**:
  - Create and customize workout templates.
  - Huge database of exercises (Strength, Cardio, Mobility, Hypertrophy).
  - Full CRUD (Create, Read, Update, Delete) capabilities.
- **🔥 Active Session**: Real-time workout tracking with built-in timer, RPE logging, and notes.
- **📅 Calendar Integration**: Drag & drop planner, schedule workouts, and sync with device calendar.
- **📈 Progress Tracking**: Visual charts for 1RM, Volume Load, and Activity stats using `fl_chart`.
- **🤝 Social Features**: Share friend codes, view friends' activity, and compete.
- **🏆 Gamification**: Earn badges, complete monthly challenges (Steps, Calories, Distance), and track streaks.
- **🌍 Localization**: Full multi-language support (English & Italian).

## 🛠 Technology Stack

- **Frontend**: Flutter (Mobile - iOS & Android)
- **Backend**: Firebase (Firestore, Auth, Storage)
- **State Management**: Riverpod (`package:provider` rimosso in EP-002)
- **UI Components**: Material 3, con i token Expressive costruiti internamente (vedi `docs/adr/001-material-3-expressive.md`)
- **Key Packages**:
  - `cloud_firestore`, `firebase_auth`
  - `flutter_riverpod`, `riverpod_annotation`
  - `table_calendar`
  - `fl_chart`
  - `google_fonts`

## ⚙️ Installation & Setup

### 1. Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: [Download & Install Flutter](https://docs.flutter.dev/get-started/install)
- **Git**: [Download Git](https://git-scm.com/)
- **IDE**: Android Studio or VS Code (with Flutter & Dart extensions)

### 2. Clone & Install

```bash
git clone https://github.com/yourusername/GymFlow.git
cd gymflow
flutter pub get
```

### 3. Firebase Configuration (Custom Setup)

To connect the app to your **own** Firebase account (replacing the default one):

1.  **Create a Project**: Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
2.  **Enable Authentication**:
    - Go to **Build > Authentication**.
    - Click **Get Started** and enable **Email/Password**.
3.  **Enable Firestore**:
    - Go to **Build > Firestore Database**.
    - Click **Create Database** (start in **Test Mode** for development).
4.  **Install Firebase CLI**:
    ```bash
    npm install -g firebase-tools
    dart pub global activate flutterfire_cli
    ```
5.  **Configure Project**:
    - Login to Firebase in your terminal: `firebase login`
    - Run the configuration command in the project root:
    ```bash
    flutterfire configure
    ```

    - Select your newly created project.
    - Select platforms (Android, iOS, Web, macOS).
    - This will overwrite `lib/firebase_options.dart` with your specific keys.
6.  **Security Rules** (Optional but Recommended):
    - Ensure your Firestore rules allow reading/writing for authenticated users.

### 4. Run the App

```bash
flutter run
```

## 🏗 Project Architecture & Database

### Folder Structure (`lib/src`)

- **`models/`**: Data classes defining the schema (e.g., `UserProfile`, `Workout`, `Exercise`).
- **`services/`**: Business logic and backend interaction (e.g., `AuthService` handling login, `FirestoreService` handling DB operations).
- **`ui/`**: UI screens, widgets, and view logic.

### Database Schema (Firestore)

The application uses a NoSQL structure with the following main collections:

- **`users`** (`UserProfile`): Stores user details, friend codes, and shared permissions.
  - _Sub-collection_: `measurements` (Body weight/height history).
- **`exercises`** (`Exercise`): Contains both default global exercises and custom user-created exercises (`isCustom: true`).
- **`programs`** (`WorkoutProgram`): Groups of workouts (e.g., "Push/Pull/Legs", "Upper/Lower").
- **`workouts`** (`WorkoutTemplate`): Individual workout templates containing lists of exercises and targets.
- **`sessions`** (`WorkoutSession`): Historical records of completed workouts with actual sets, reps, and weights performed.
- **`scheduled_workouts`** (`ScheduledWorkout`): Calendar events linking a specific date to a workout template.

## 📱 Screenshots

_(Add your screenshots here later)_

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
