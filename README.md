# Orama Admin

_A Flutter mobile & web app for centralized stock, reporting, and inventory sync across Orama’s factory, stores, and points‑of‑sale._

> **Status:** Private – in active development 

---

## Key Features

| # | Feature | Details |
|---|----------|---------|
| 1 | **Centralized Stock** | Single Firestore collection keeps factory, store, and admin apps in sync, with offline‑first caching via GetStorage. |
| 2 | **Replenishment Reports** | Create, copy, edit and export replenishment ("Reposição") reports with MobX‑powered forms. |
| 3 | **Real‑time Dashboards** | Syncfusion charts & gauges visualize temperature history and stock levels in real time. |
| 4 | **Offline Support** | Read/write locally when offline, auto‑sync when the device reconnects. |
| 5 | **PDF & Excel Exports** | One‑tap generation of PDF romaneios and Excel spreadsheets for compliance and sharing. |
| 6 | **Role‑based Auth** | Firebase Authentication with role guards for factory, store, and admin users. |

---

## Tech Stack

- **Flutter**
- **Firebase** (Auth ▸ Firestore ▸ Storage)  
- **MobX** for reactive state  
- **GetStorage** for local persistence  
- **pdf / excel** packages for export  
- **CI/CD**: GitHub Actions ▸ Codemagic (Shorebird hot‑patch ready)

---

## Architecture Overview

```
┌────────────┐          realtime           ┌──────────────┐
│ Factory App│ ──────── Firestore ───────▶│ Admin Portal │
└────────────┘         (stock)             └──────────────┘
       ▲                                     │   ▲
       │ write stock‑in                      │   │
       ▼                                     ▼   │
┌────────────┐        sync / offline       ┌──────────────┐
│ Store App  │ ◀──────────────────────────│  Orama Stock │
└────────────┘                             └──────────────┘
```

*Clean Architecture:* UI → Stores → Services → Firebase datasource.

---

## Getting Started

### 1. Prerequisites

- Flutter SDK `>= 3.10`
- Dart `>= 3.2`
- A Firebase project (enable **Auth** & **Firestore**)

### 2. Clone & Install

```bash
$ git clone https://github.com/your-username/orama_admin.git
$ cd orama_admin
$ flutter pub get
```

### 3. Configure Firebase

1. Run `flutterfire configure` and select your project.  
2. Copy `google-services.json` (Android) & `GoogleService-Info.plist` (iOS) into `android/` & `ios/` folders.  
3. Ensure Firestore rules & indexes match `/firebase/firestore.rules`.

### 4. Run the App

```bash
# Android / iOS
flutter run

# Web
flutter run -d chrome --web-renderer canvaskit
```

### 5. Build Release

```bash
flutter build apk   # Android
flutter build ios   # iOS
flutter build web   # PWA
```

---

## Folder Structure

```
lib/
├── main.dart            # entry point, routes
├── pages/               # UI screens
│   ├── home/
│   ├── relatorios/
│   └── reposicao/
├── stores/              # MobX stores
├── services/            # Firebase & API services
├── utils/               # helpers, extensions, themes
└── widgets/             # reusable components
```

> **Tip:** Each `Store` holds observable state; `Services` are framework‑free – easy to unit‑test.

---

## Testing

- Unit tests live in `test/` – run with `flutter test`.
- Widget tests cover critical flows such as report creation.

---

## Documentation

Generate API docs with:

```bash
flutter pub global activate dartdoc
flutter pub global run dartdoc
```

The HTML output in `doc/api` can be deployed with **GitHub Pages**.

---

## Contributing

> This repository is private. Contact **@rikelmyso7** for access.

1. Fork and create a feature branch (`feat/my-feature`).
2. Commit using conventional commits.
3. Open a Pull Request.

---

## License

Released under the MIT License – see [`LICENSE`](LICENSE) for details.

---

## 📸 Screenshots

<p align="center">
  <img src="docs/screenshots/orama.png" width="250" />
</p>

---

### Maintainer

<table>
  <tr>
    <td align="center"><img src="https://avatars.githubusercontent.com/u/000000?v=4" width="80" /><br/>Rikelmy Roberto<br/><sub>Founder @ Orama</sub></td>
  </tr>
</table>

