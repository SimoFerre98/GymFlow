# GymFlow 🏋️‍♂️

**GymFlow** is a dynamic, highly customizable fitness application built with **Flutter** and **Firebase**. It is designed to help users track their workouts, monitor progress, and connect with gym buddies in real-time.

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
- **State Management**: Provider
- **UI Components**: Material 3 Design
- **Key Packages**:
  - `cloud_firestore`, `firebase_auth`
  - `provider`
  - `table_calendar`
  - `fl_chart`
  - `google_fonts`

## ⚙️ Getting Started

1.  **Clone the repository**:

    ```bash
    git clone https://github.com/yourusername/GymFlow.git
    cd gymflow
    ```

2.  **Install Dependencies**:

    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration**:
    - This project uses Firebase. You must provide your own `firebase_options.dart`.
    - Run `flutterfire configure` to generate the file for your project.
    - See [FlutterFire Documentation](https://firebase.flutter.dev/docs/overview) for details.

4.  **Run the App**:
    ```bash
    flutter run
    ```

## 📱 Screenshots

_(Add your screenshots here later)_

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
