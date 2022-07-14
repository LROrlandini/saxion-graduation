Latest App version currently uploaded to testing track in Google Play Console.

Google Play Console log in details:

    Username: systeembeheer@aemics.nl

    Password: M?re2?n5Agg`MP{V

Process followed can be found on:

https://docs.flutter.dev/deployment/android

# Gadget Board
When first cloning this repository, navigate to /app and edit key.properties, updating the first part of storeFile to match your computer's path.

# Deploying to paired phone
The paired Android phone needs to have USB debugging enabled in the Developer Options. Once connected, the phone's name will show as a target for running.

## VS Code
If using VS Code with the Flutter extension, the app can be run in debug mode by opening main.dart and pressing F5.
Alternatively, navigate via the terminal to /src01 and type:

```bash
flutter run --release
```

## Android Studio
The play button will launch the app on the phone.

Both options have HotReload enabled for further development. Before deploying, ensure your phone's name is showing as a target, either at the bottom right corner on VS Code or in the drop-down menu next to the play button on Android Studio.