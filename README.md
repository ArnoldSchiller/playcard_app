# Playcard App

This repository contains the source code for the Playcard Flutter application.

---

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

* **Flutter SDK**: Ensure you have Flutter installed. Follow the official Flutter installation guide: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
* **Android Studio / Android SDK**: For Android development, you'll need Android Studio and the Android SDK.
* **Java Development Kit (JDK)**: This project is configured to use Java 17 for Android compilation. Please ensure you have JDK 17 installed and configured correctly. You can download OpenJDK from Adoptium: [https://adoptium.net/temurin/releases/](https://adoptium.net/temurin/releases/)
* **Linux Build Dependencies (for Linux users)**:
    For building and running the application on Linux, you need several development libraries. On Debian/Ubuntu-based systems, these can be installed with:
    ```bash
    sudo apt update
    sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libappindicator3-dev
    ```
    Additionally, for media playback via `media_kit`, the **mpv development libraries** are required for building and the **mpv runtime library** for running the application. On Debian/Ubuntu-based systems, install:
    ```bash
    sudo apt install libmpv-dev # Required for building
    # libmpv1 (or libmpv) is usually installed as a dependency or needed for runtime
    ```
    *(Note: Package names might vary on other Linux distributions. Refer to your distribution's documentation.)*

### Installation and Setup

1.  **Clone the repository:**
    ```bash
    git clone [YOUR_REPOSITORY_URL]
    cd playcard/example/app # Navigate into the app directory
    ```
    *(Replace `[YOUR_REPOSITORY_URL]` with the actual URL of your Git repository)*

2.  **Get Flutter dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Android-Specific Configuration (Important!)**

    This project requires a specific Android NDK version and Java compatibility settings. These are already configured in `android/app/build.gradle.kts` within this repository, but it's good to be aware of them:

    * **Android NDK Version**: The project explicitly uses Android NDK `27.0.12077973`. Android Studio should prompt you to install this version if you don't have it. If not, you can install it via SDK Manager in Android Studio (`Appearance & Behavior > System Settings > Android SDK > SDK Tools` tab).
    * **Java Compatibility**: The project is set to compile with Java 17. Ensure your `JAVA_HOME` environment variable points to a JDK 17 installation.

4.  **Run the application (Debug Mode):**

    * **Connect an Android device** (with USB debugging enabled) or start an Android Emulator.
    * To run on **Android**:
        ```bash
        flutter run
        ```
    * To run on **Linux Desktop**:
        ```bash
        flutter run -d linux
        ```
        *(Ensure you have enabled Linux desktop support for Flutter: `flutter config --enable-linux-desktop`)*

    This command will build and install the debug version of the app on your connected device/emulator or run it on your Linux desktop.

---

## Important Notes for Developers

* **Debug vs. Release Builds**: This repository is configured for easy **debug builds**.
* **App Signing (for Release)**: **This repository does NOT contain any sensitive signing keys (`key.properties`) or release signing configurations.** If you plan to build a **release version** of the app for distribution (e.g., to Google Play Store), you will need to:
    1.  Generate your own upload keystore.
    2.  Create a `key.properties` file in the root of your Flutter project (sibling to `pubspec.yaml`) containing your keystore details.
    3.  Add the `signingConfigs` block and the `signingConfig` assignment to the `release` build type in `android/app/build.gradle.kts` (refer to official Flutter documentation on Android app signing).
    **Never commit your `key.properties` file or sensitive signing credentials to Git!**
* **Package Updates**: You may occasionally see warnings about outdated Flutter packages. You can check for newer versions with `flutter pub outdated`. Update packages by modifying `pubspec.yaml` and running `flutter pub get`, but be mindful of breaking changes.

---

## License

This project is licensed under the **MIT License 1.0**.

Copyright (c) 2025 Arnold Schiller <schiller@babsi.de>

For the Media-kit library, the copyright is:
Copyright (c) 2021 & onwards Hitesh Kumar Saini <saini123hitesh@gmail.com>

---
