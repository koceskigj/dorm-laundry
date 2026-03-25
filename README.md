# dorm_laundry_app

Digital laundry booking system for dormitory students.

## Requirements

Before running the application, make sure you have the following installed:
  - Flutter SDK (version 3.x or later)
  - Dart SDK (included with Flutter)
  - Android Studio or VS Code with Flutter plugin
  - Firebase project configured for the application
  - Android emulator or physical Android device

## Clone the repository
 
  - git clone https://github.com/koceskigj/dorm-laundry.git
  - cd dorm-laundry

 ## Install the dependencies
 
  - flutter pub get
 
 ## Firebase setup
 
The application uses Firebase Authentication and Cloud Firestore.
Make sure the Firebase configuration files exist in the project:

  - android/app/google-services.json
 
 
If these files are missing, create a Firebase project and configure the app using:

  - flutterfire configure

 ## Run the application
 
Either run the application with the help of an Android Emulator, or run it directly in Chrome.

 - flutter run 
