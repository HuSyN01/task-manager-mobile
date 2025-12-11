# Task Manager Mobile 📱

A modern, feature-rich mobile application for managing tasks, built with **Flutter**. This app serves as the mobile companion to the Task Manager web platform, providing seamless synchronization and powerful productivity tools on the go.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-%232D3748.svg?style=for-the-badge&logo=riverpod&logoColor=white)

## ✨ Key Features

### 🚀 Productivity & Workflow
-   **Smart Dashboard**: visualized statistics of your workspace activity at a glance.
-   **Shake-to-Inspect**: 👋 Shake your device to instantly view your most urgent "To Do" task.
-   **Swipe Actions**: Swiftly manage tasks with intuitive swipe gestures:
    -   Swipe **Right** to move a task forward (Todo → In Progress → Done).
    -   Swipe **Left** to move a task backward.
-   **Optimistic UI**: Experience zero-latency interactions with instant UI updates.

### 📝 Task Management
-   **Full CRUD**: Create, Read, Update, and Delete tasks effortlessly.
-   **Date Filters**: Client-side filtering to focus on tasks for specific days.
-   **Rich Details**: Support for priorities, deadlines, descriptions, and tags.

### 🔐 Security & Architecture
-   **Secure Authentication**: Robust login and registration flows with session persistence.
-   **Cookie-based Auth**: Secure cookie management using `dio_cookie_manager` and `cookie_jar`.
-   **Clean Architecture**: Built on a modular, feature-first architecture for scalability.

---

## 🛠️ Tech Stack

-   **Framework**: [Flutter](https://flutter.dev/) (SDK >3.10.0)
-   **Language**: [Dart](https://dart.dev/)
-   **State Management**: [Flutter Riverpod](https://riverpod.dev/)
-   **Routing**: [GoRouter](https://pub.dev/packages/go_router)
-   **Networking**: [Dio](https://pub.dev/packages/dio)
-   **Sensors**: [Shake](https://pub.dev/packages/shake) (Accelerometer access)
-   **UI Components**: Material 3 Design, Google Fonts

---

## 🚀 Getting Started

### Prerequisites

-   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.
-   An Android Emulator or iOS Simulator.
-   The backend API running locally (see Backend Setup below).

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/HuSyN01/task-manager-mobile.git
    cd task_manager_mobile
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Configure Backend URL**
    The app is pre-configured to connect to a local backend.
    -   **Android Emulator**: `http://10.0.2.2:8787`
    -   **iOS Simulator**: `http://127.0.0.1:8787`

    *Note: Ensure your backend server is running on port 8787.*

4.  **Run the App**
    ```bash
    flutter run
    ```

---

## 📂 Project Structure

This project follows a **Feature-First** architecture pattern:

```
lib/
├── core/                   # Global core functionality (Network, Theme, Router)
├── features/
│   ├── auth/               # Authentication (Login, Register, State)
│   ├── dashboard/          # Dashboard Screen & Widgets
│   └── tasks/              # Task Domain, Data, Presentation
└── main.dart               # App Entry Point
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
