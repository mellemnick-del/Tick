# Tick

One-tap iPhone game: a hand sweeps around a watch dial, tap when it hits the glowing marker.

- SwiftUI, iOS 17+, iPhone only, portrait. No third-party libraries, no backend, no accounts.
- Bundle ID: com.nickmellem.tick
- `prototype/index.html` is the web prototype the native game is based on. Tuning values in
  `Tick/GameModel.swift` match it.
- Project uses Xcode folder sync: any file added under `Tick/` is part of the app automatically.
- Version 1.0 collects no data (privacy label "Data Not Collected"). Best score is stored with
  UserDefaults, declared in `Tick/PrivacyInfo.xcprivacy`.

## Working with Nick
- Explain Xcode and App Store steps click by click in plain language. Keep messages short and
  lead with what he needs to do.
- Never use em dashes.
- iOS code can't be compiled here: write carefully, avoid uncommon APIs, and say the first build
  may have errors. He sends screenshots of Xcode errors; fix and push, then he uses Integrate > Pull.
- Main branch = what ships. Future versions go on their own branch (v1.1, etc.).
- Ask before anything public or hard to undo. No real brand names, logos, or trademarks. Keep his
  personal brands out. No buttons that do nothing. No features he didn't ask for in this version.
