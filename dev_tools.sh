#!/bin/bash

# Handle arguments
case "$1" in
    -c)
        echo "Running Clean Flutter Run..."
        flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter run
        ;;
    -b)
        echo "Running Flutter Build APK and Install..."
        flutter build apk && adb install build/app/outputs/flutter-apk/app-release.apk
        ;;
    -m)
        echo "Running Flutter Run for macOS..."
        flutter run -d macos
        ;;
    -r)
        echo "Running Flutter Run..."
        flutter run
        ;;
    -w)
        echo "Running Dart Run Build Runner Watch..."
        dart run build_runner watch
        ;;
    -d)
        echo "Running Dart Run Build Runner Build..."
        dart run build_runner build --delete-conflicting-outputs
        ;;
    -f)
        echo "Running Flutter Clean..."
        flutter clean
        ;;
    -g)
        echo "Running Flutter Pub Get..."
        flutter pub get
        ;;
    *)
        echo "Usage: $0 [-c | -b | -m | -r | -w | -d | -f | -g]"
        echo "  -c: Clean Flutter Run (flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter run)"
        echo "  -b: Flutter Build APK and Install"
        echo "  -m: Flutter Run for macOS"
        echo "  -r: Flutter Run"
        echo "  -w: Dart Run Build Runner Watch"
        echo "  -d: Dart Run Build Runner Build"
        echo "  -f: Flutter Clean"
        echo "  -g: Flutter Pub Get"
        exit 1
        ;;
esac

exit 0