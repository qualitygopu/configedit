# ConfigEditor (Announce Config Editor)

A Flutter desktop/web application for editing the configuration of **QTRON** time-announcement devices — alarm-based Tamil/religious audio announcement clocks that read a `timeAnnounce.qtr` config file from a `_QTRON` folder on a removable drive (SD card / USB).

The app auto-detects a connected QTRON drive, lets you visually edit its alarm schedules, silent hours, sound library, and playlists, and writes the result back as a Base64-encoded JSON file the device can read. It also includes a small file manager for staging audio files onto the device.

## Features

- **QTRON drive detection** — automatically finds a `_QTRON` folder on connected removable drives, or lets you pick one manually.
- **Alarms Configuration** — create/edit/reorder/delete scheduled announcements with fine-grained scheduling (minute offsets, hour ranges, day-of-month ranges, month ranges, weekdays) and an assigned list of sound clips to play. Alarms auto-sort by end time.
- **Silent Hours** — define time ranges during which announcements are suppressed.
- **Sound Library (Song Master)** — manage the catalog of sound clips/phrases mapped to on-device folders, with an "Analyze" action that scans the QTRON drive and updates file counts per folder (and warns about missing folders).
- **Playlist Manager** — build named playlists referencing sound-clip indices.
- **Raw JSON Editor** — directly view/edit the underlying config as pretty-printed JSON, with validation and two-way sync to the structured editors.
- **File Manager** — browse the QTRON drive's folder tree (system folders like `@CONF`, `DT`, `DW`, `HR`, `MO`, `NN`, `PN` are hidden/protected), drag-and-drop or pick files to import, copy/cut/paste with a queued copy-task system (backed up to `filecopy.json` before execution), bulk rename/randomize pending files, and multiply/duplicate selected files.
- **Themes** — Modern (Indigo) and Classic (Blue) styles, each with light/dark variants, plus a normal/reduced text-size toggle.
- **Save / Save As** — writes the edited config back to `timeAnnounce.qtr` as Base64-encoded JSON, either in place or via a save dialog.

## Tech stack

- [Flutter](https://flutter.dev/) (SDK ^3.8.1) targeting **Windows**, **macOS**, and **Web**
- [GetX](https://pub.dev/packages/get) for state management, routing, and dialogs
- [file_picker](https://pub.dev/packages/file_picker) and [desktop_drop](https://pub.dev/packages/desktop_drop) for file selection/drag-and-drop
- [audioplayers](https://pub.dev/packages/audioplayers) for previewing sound clips
- Platform-specific file access via `dart:io` on desktop, with an AppleScript (`osascript`) fallback on macOS for filesystem operations that `dart:io` can't perform directly (e.g. on some external volumes), and a stub/web implementation for browser support

## Project structure

```
lib/
  main.dart                    App entry point, theming
  controllers/
    config_controller.dart     Loads/saves the config, holds alarms/silentHours/songMaster/playlists state
    file_manager_controller.dart  QTRON folder browsing, copy/cut/paste queue, drag-drop import
  models/
    config_model.dart          Config, AlarmConfig, SongMasterItem, Playlist data models
  screens/
    main_shell.dart            Sidebar navigation + top toolbar shell
    alarms_screen.dart         Alarm list view
    file_manager_screen.dart   File browser UI
    playlist_creator_screen.dart
    raw_json_screen.dart       Raw JSON editor
  widgets/
    alarm_editor.dart          Alarm scheduling editor dialog
    silent_hours_section.dart
    song_master_section.dart
  utils/
    file_helper*.dart          Platform-specific file/drive access (desktop, web, stub)
```

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.8.1), with the Windows and/or macOS desktop toolchains enabled as needed.

### Install dependencies

```bash
flutter pub get
```

### Run

```bash
flutter run -d windows   # Windows desktop
flutter run -d macos     # macOS desktop
flutter run -d chrome    # Web
```

### Build

```bash
flutter build windows
flutter build macos
flutter build web
```

Windows app icons are generated from `assets/icon/Logo.png` via `flutter_launcher_icons` (`dart run flutter_launcher_icons`).

## Config format

The app reads/writes a JSON document with four top-level sections — `AlarmConfig`, `silentHours`, `SongMaster`, and `Playlists` — which is Base64-encoded when saved as `timeAnnounce.qtr` on the device (see `ConfigController.defaultJson` in [config_controller.dart](lib/controllers/config_controller.dart) for a sample/default config). The Raw JSON editor also accepts plain (non-encoded) JSON for convenience when loading.
