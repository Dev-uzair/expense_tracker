# Expense Tracker

A Flutter-based mobile application designed to help users track expenses, manage budgets, and gain insights into their spending habits through visual analytics.

## Table of Contents

- [Try the App](#-try-the-app)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Tech-Stack](#️-tech-stack)
- [Architecture](#-architecture)
- [Getting-Started](#-getting-started)
- [Contributing](#-contributing)
- [License](#-license)

## 📲 Try the App

| Platform | Link |
| :--- | :--- |
| 🌐 **Web** (runs in your browser) | [dev-uzair.github.io/expense_tracker](https://dev-uzair.github.io/expense_tracker/) |
| 🤖 **Android** (APK download) | [expense-tracker.apk](https://github.com/Dev-uzair/expense_tracker/releases/latest/download/expense-tracker.apk) |

Both are rebuilt and published automatically on every push to `main`, so the links always point to the latest version. All builds are listed on the [Releases](https://github.com/Dev-uzair/expense_tracker/releases) page.

**Installing the APK:** open the link on your Android phone, download the file and tap it. Android will ask you to allow installing apps from your browser ("Install unknown apps").

**Notes:**
- Releases are signed with the app's own key (when the signing secrets below are set up), so a new version installs over the old one and keeps your data. If a release says it used a *debug key*, uninstall the old version first.
- The web version stores data in your browser, so it isn't shared between devices or browsers.
- Use **⋮ → Back up data** to save everything to a `.json` file, and **⋮ → Restore from backup** to load it again, e.g. on a new phone or before reinstalling.

### Setting up the APK signing key (maintainers, one time)

1. Create a key (keep the file and passwords safe, since losing them means users must reinstall):
   ```sh
   keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. In **Settings → Secrets and variables → Actions → New repository secret**, add:
   - `ANDROID_KEYSTORE_BASE64`: output of `base64 -i upload-keystore.jks` (macOS) or `base64 -w0 upload-keystore.jks` (Linux)
   - `ANDROID_KEYSTORE_PASSWORD`: the keystore password
   - `ANDROID_KEY_ALIAS`: `upload`
   - `ANDROID_KEY_PASSWORD`: the key password (same as the keystore password unless you chose a different one)
3. Never commit the `.jks` file; it is ignored by `android/.gitignore`.

## ✨ Features

- **Transaction Management**: Easily add, view, edit, and delete income and expense records.
- **Category Management**: Organize transactions with predefined and custom categories.
- **Interactive Analytics**: Visualize your finances with interactive charts (Pie, Bar, Line) and reports.
- **Budgeting Tools**: Set and monitor budgets for different categories and time periods.
- **Smart Alerts**: Receive notifications when you're approaching your budget limits.
- **Data Export**: Export your transaction data to CSV or generate PDF reports.
- **Customization**: Personalize the app with light and dark themes, and other preferences.
- **Security**: Protect your data with PIN or biometric authentication.
- **Offline First**: All features are available offline.

## 📸 Screenshots

*(Add screenshots of the application here to showcase the UI)*

| Dashboard | Transactions | Analytics |
| :---: | :---: | :---: |
| *Dashboard Screenshot* | *Transactions Screenshot* | *Analytics Screenshot* |

## 🛠️ Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Provider / Riverpod / BLoC
- **Database**: Hive / SQLite / Isar
- **Charts**: `fl_chart`
- **Date/Time Formatting**: `intl`
- **Security**: `flutter_secure_storage`, `local_auth`
- **Notifications**: `flutter_local_notifications`

## 🏗️ Architecture

This project follows **Clean Architecture** to ensure a separation of concerns, making the code more scalable and maintainable.

- **Presentation Layer**: Contains UI components, widgets, and state management logic.
- **Domain Layer**: Includes business logic, use cases, and entities. It's the core of the application and is independent of other layers.
- **Data Layer**: Implements repositories and manages data from local data sources.

## 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

Make sure you have the Flutter SDK installed on your machine.
*   [Flutter Installation Guide](https://flutter.dev/docs/get-started/install)

### Installation

1.  Clone the repository.
2.  Install the dependencies:
    ```sh
    flutter pub get
    ```
3.  Run the app:
    ```sh
    flutter run
    ```

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m '''Add some AmazingFeature'''`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

*(Note: You'''ll need to add a LICENSE file to your project.)*
