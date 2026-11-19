<img width="1600" height="840" alt="ss7" src="https://github.com/user-attachments/assets/3ed801bd-62e8-4632-9e42-3ddbc655c7e0" />
<img width="1600" height="840" alt="ss2" src="https://github.com/user-attachments/assets/6fc75e36-c1d7-43b1-ade3-550c3ca7d5d5" />
<img width="1600" height="840" alt="ss3" src="https://github.com/user-attachments/assets/20e27781-f371-4bad-b8c6-ded14b6aa0f0" />
<img width="1600" height="840" alt="ss4" src="https://github.com/user-attachments/assets/a1522429-b349-473d-a7b9-4454d2132e87" />
<img width="1600" height="840" alt="ss5" src="https://github.com/user-attachments/assets/d15b3674-c017-4d58-9eb7-4fa01a8d37dc" />
<img width="1600" height="840" alt="ss6" src="https://github.com/user-attachments/assets/8fae65e2-be7f-4318-a408-5374f5c136e0" />
<img width="1600" height="840" alt="ss1" src="https://github.com/user-attachments/assets/451ea709-14d9-4fa0-b0cf-bc60211e607b" />
# Seaside Tasks — Flutter Task Management App

Sea-blue / swan-lake themed task manager with SQLite, repeat tasks, local notifications,
progress tracking, CSV / PDF / email export, light + dark mode, sparkly celestial font
(Cinzel Decorative + Quicksand), hover buttons and glass cards.

## Features (assignment checklist)
| Requirement | Where |
|---|---|
| Flutter setup + SQLite | `lib/db.dart` (tables `tasks`, `subtasks`) |
| Today / Repeated / Completed views | `lib/screens/today_screen.dart`, `repeated_screen.dart`, `completed_screen.dart` |
| Add / edit / delete / mark complete | `add_edit_screen.dart`, `task_card.dart` (swipe left = delete + Undo) |
| Light & dark mode, notification sound | `settings_screen.dart`, `lib/theme.dart` |
| Subtasks + progress bar / % | `task_card.dart`, ring on the Today screen |
| Export CSV, PDF, Email | `lib/export.dart` (Settings → Export tasks) |
| Repeat daily / chosen weekdays / every N days, auto reset | `lib/models.dart`, `lib/state.dart` (`toggleComplete`) |
| Local notifications | `lib/notifications.dart` |
| Tests | `test/widget_test.dart` |

## Setup (one time)

1. Unzip this folder.
2. Make a fresh Flutter project so the Android/iOS folders are generated:
   ```bash
   flutter create seaside_tasks
   ```
3. Copy these from the unzipped folder **into** the new `seaside_tasks/` project, replacing what is there:
   `lib/`, `assets/`, `test/`, `pubspec.yaml`
4. Inside the project run:
   ```bash
   flutter pub get
   ```

## Running in Chrome (web) instead of a phone

Do this once in the project folder, then run again:
```bash
flutter pub get
dart run sqflite_common_ffi_web:setup
flutter run -d chrome
```
(`setup` copies `sqlite3.wasm` into `web/`.) Notifications, sounds and file export only work on a real Android/iOS device.

## In-app alarm (works in Chrome too)

While the app (or browser tab) is open, a timer checks every 10 seconds for due tasks and rings the
Dragon Alert sound with a reminder dialog (Dismiss / Mark done). Real background notifications
(app closed) need an Android phone with the setup below.

## Android changes (needed for notifications)

**a) `android/app/build.gradle.kts`** (or `build.gradle` on older Flutter)

Kotlin DSL (new projects):
```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        // keep the sourceCompatibility / targetCompatibility lines that are already there
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```
Groovy (older projects):
```groovy
android {
    compileOptions { coreLibraryDesugaringEnabled true }
}
dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```

**b) `android/app/src/main/AndroidManifest.xml`**

Above `<application ...>` add:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```
Inside `<application ...>` (before `</application>`) add:
```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

## Custom notification sound (Dragon Alert)

Copy the folder `android_res/raw/` from this zip into the project so the file ends up at:
```
android/app/src/main/res/raw/dragon_alert.mp3
```
(create the `raw` folder if it does not exist). It is the default sound; you can change it in Settings.
After adding it, do a full rebuild (`flutter clean` then `flutter run`) and uninstall any older build of the app,
because Android remembers a notification channel's sound.

## Run & build APK
```bash
flutter run
flutter test
flutter build apk --release      # build/app/outputs/flutter-apk/app-release.apk
```

## Submit on GitHub
```bash
git init
git add .
git commit -m "Seaside Tasks - Flutter task manager"
git branch -M main
git remote add origin https://github.com/<your-username>/seaside_tasks.git
git push -u origin main
```
Upload the `.apk` and the demo video to the repo (or as a GitHub Release).

## Notes
* Targets Android / iOS (SQLite via `sqflite`).
* Repeating tasks: when you tick one, a finished copy goes to **Completed** and the task
  automatically resets to its next due date with subtasks un-ticked.
* Notification sounds use system sounds (Default / Chime / Ringtone / Alarm / Silent).
  Android 13+ asks for notification permission on first launch.

## UI refresh (glass theme)
- Transparent, shiny glass cards + bottom bar (`GlassCard`, `GlassShine` in `lib/widgets.dart`)
- Animated background: slow zoom/drift photo (`assets/images/bg_pond.jpg`, `bg_forest.jpg`), blue-green wash, rising bubbles, twinkling stars
- Animations: staggered fade/slide-in task cards, breathing + button, glossy progress bars, tab fade/slide
