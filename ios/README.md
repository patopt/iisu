# iiSU for iOS

A native SwiftUI port of the iiSU frontend, built to produce an **unsigned IPA**
for sideloading.

```
ios/
├── project.yml               # XcodeGen spec — the .xcodeproj is generated, not committed
└── iiSU/
    ├── Sources/
    │   ├── App/              # App entry point
    │   ├── Models/           # Catalog, platform, game
    │   ├── Services/         # Library, emulator launch, updates, gamepad, RetroAchievements
    │   ├── Support/          # Artwork loading, keychain, document picker
    │   └── Views/            # Onboarding, home, platform, game detail, settings
    └── Resources/
        ├── Assets.xcassets   # App icon, launch colour
        ├── Platforms/        # Platform art recovered from the repo's asset history
        └── emulators.ios.json
```

## Building

```sh
brew install xcodegen
xcodegen generate --spec ios/project.yml
open ios/iiSU.xcodeproj
```

For an unsigned build matching CI:

```sh
xcodebuild archive \
  -project ios/iiSU.xcodeproj -scheme iiSU -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/iiSU.xcarchive \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
```

CI does this on every push and publishes the IPA as a workflow artifact — see
[`.github/workflows/ios-unsigned-ipa.yml`](../.github/workflows/ios-unsigned-ipa.yml).
Pushing an `ios-v*` tag additionally attaches the IPA to a GitHub release.

The IPA is **not signed**. Install it with AltStore, SideStore or Sideloadly,
which sign it with your own Apple ID on device.

## What changed from Android, and why

iiSU on Android is a home-screen replacement that scans arbitrary storage and
launches emulators through explicit intents. iOS permits none of those three
things. The port keeps the product — a visuals-first library you browse with a
controller — and replaces the mechanisms underneath it.

| Android | iOS | Reason |
| --- | --- | --- |
| Replaces the home launcher | Ordinary app | iOS reserves the home screen; there is no launcher API |
| Scans a user-chosen ROM folder anywhere on device | Reads `Documents/ROMs/<system>/` inside the app container, plus document-picker import | An app cannot walk the filesystem outside its sandbox |
| Launches emulators via `Intent` with a ROM path | Share-sheet handoff (`ShareLink`), plus URL-scheme detection and launch | No API hands another app a path into our container |
| `emuladores.json` — packages, activities, command lines | `emulators.ios.json` — URL schemes, document-acceptance flags | Intents have no iOS counterpart |
| Installs emulator updates in-app | Links to the emulator's install page | iOS apps cannot install other apps |
| Built-in updater installs new APKs | Updater reports the new version and links to the release | Sideloaded apps are refreshed by AltStore/SideStore, not self-install |

Unchanged in spirit: controller-first navigation (GameController instead of
Android input), theme colour and browsing style, home-page shortcuts and
collections, onboarding flow, and the RetroAchievements profile link.

### Emulator launching, concretely

There is no public API to start a third-party emulator against a file in our
container. Two mechanisms exist and iiSU uses both:

1. **`canOpenURL` / `open`** — detects whether an emulator is installed and
   brings it to the front. Requires every scheme to be declared in
   `LSApplicationQueriesSchemes`; without that the check silently returns
   `false` rather than failing loudly.
2. **The system document handoff** — the only route that actually transfers a
   specific ROM. It copies the game into the emulator's own container, so it is
   the default "Play" action.

`emulators.ios.json` records which emulators accept documents and which can only
be launched, so the UI can say which of the two a given game will get.

### Not ported yet

- **ROM hashing for RetroAchievements.** Credential storage and profile sync are
  in; per-system hashing is not. It needs the system-specific hashing rules and
  a background window iOS does not grant for a large library.
- **Scraping and box art.** Game tiles currently fall back to platform art.
- **Dual-screen support.** No iOS device exposes a second internal display.

## Update catalog

The app's updater reads the same `updates/catalog.json` the Android build uses
and looks for an `ipa` artifact. That key does not exist yet — until an iOS
release is published, the app correctly reports that no iOS build is available.
When the first release ships, add:

```json
"ipa": {
  "version": "0.1.0",
  "releasePageUrl": "https://github.com/patopt/iisu/releases/tag/ios-v0.1.0"
}
```
