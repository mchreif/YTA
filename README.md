# YTA Lebanon — Native iOS App

The official app of the **Yammouneh Tourism Association (YTA)**, a community-led NGO promoting sustainable tourism, heritage preservation, and cultural festivals in Yammouneh, Bekaa Valley, Lebanon. It is a fully native SwiftUI recreation of [ytalebanon.org](https://ytalebanon.org/) — **no WebView anywhere** — extended with app-exclusive community features.

**What's inside:**

- **Animated splash intro** — the YTA logo over a living `MeshGradient`, auto-dismisses into the app
- **Home** — four full-screen pages with vertical snap paging: full-bleed hero video → 01 Mission (six program cards, 2018/2019/2023 festival videos) → 02 Impact (animated counters) → 03 Board
- **Yammouneh** — photo gallery with a native lightbox (pinch zoom, paging, sharing)
- **Community** — broadcast alerts and project polls fed live from ytalebanon.org, with offline caching, unread badges, quiet background notifications, and confetti-on-vote (see [`Server/ADMIN-GUIDE.md`](Server/ADMIN-GUIDE.md) for how the admin publishes content)
- **Media** — Instagram carousel (@yta_leb) and Arabic press coverage in in-app Safari
- **Connect** — call/email/directions, MapKit satellite map, share sheet

Tech: SwiftUI, MVVM with Observation, async/await, MapKit, AVKit, BackgroundTasks, English + Arabic localization, light/dark mode, Dynamic Type, VoiceOver. **Minimum iOS: 18.0** (the app uses iOS 18 SwiftUI APIs: `MeshGradient`, the `Tab` builder, `onScrollVisibilityChange`, `onScrollGeometryChange`).

## Project facts

| | |
|---|---|
| Project / scheme name | `YTA` |
| Bundle identifier | `org.ytalebanon.app` |
| Deployment target | iOS 18.0 |
| Project generator | [XcodeGen](https://github.com/yonaskolb/XcodeGen) via [`project.yml`](project.yml) |
| Code signing | **Not required** for simulator builds |

The `.xcodeproj` is intentionally **not committed** — it is generated from `project.yml`, so the project definition is always reviewable as plain text.

## Repository layout

```
├── project.yml                  XcodeGen project definition (target, scheme, settings)
├── Config/Info.plist            Custom Info.plist keys (fonts, URL scheme, background refresh)
├── YTA/                         All app sources
│   ├── App/                     YTAApp (entry point), RootView (tabs + deep links)
│   ├── Models/  ViewModels/  Views/  Services/  Managers/  Theme/  Extensions/
│   ├── Resources/               Videos, fonts, seed JSON, Localizable.xcstrings
│   └── Assets.xcassets          Images, AppIcon, AccentColor
├── Server/                      Ready-to-upload feed files + admin guide (not part of the app target)
├── ARCHITECTURE.md              Technical documentation
└── .github/workflows/ios-simulator-build.yml
```

> **Important:** upload the **contents of this folder** as the root of your GitHub repository, so `project.yml` and `.github/` sit at the repository root.

## Building on GitHub Actions (no Mac needed)

1. Create a GitHub repository and push this folder's contents to `main` (or `master`).
2. The **iOS Simulator Build** workflow runs automatically on every push (or start it manually from the *Actions* tab via *Run workflow*).
3. The workflow, on a macOS 15 runner:
   - installs XcodeGen (`brew install xcodegen`)
   - generates the project (`xcodegen generate`)
   - builds without signing:
     `xcodebuild -scheme YTA -sdk iphonesimulator -configuration Debug -derivedDataPath build CODE_SIGNING_ALLOWED=NO build`
   - zips `YTA.app` from `build/Build/Products/Debug-iphonesimulator/`
   - uploads it as the artifact **`YTA-iOS-Simulator-App`**

### Downloading the build

Open the finished workflow run on GitHub → *Artifacts* section (bottom of the run summary) → download **YTA-iOS-Simulator-App** (a zip containing `YTA.app`).

## Testing in your browser with Appetize.io

[Appetize.io](https://appetize.io) streams a real iOS simulator to your browser — ideal since you have no Mac:

1. Sign up for a free Appetize account (the free tier is enough for testing).
2. Click **Upload** and select the `YTA-Simulator-App.zip` artifact you downloaded (Appetize accepts a zipped simulator `.app` directly).
3. Choose an iPhone device, **iOS 18 or newer**, and launch — the app runs in your browser, fully interactive.

## Building locally on a Mac (when you have one)

```bash
brew install xcodegen
xcodegen generate
open YTA.xcodeproj        # then press Run in Xcode (16+), or:
xcodebuild -scheme YTA -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

Running in the simulator requires **no Apple Developer account and no signing**.

## What requires an Apple Developer account later

| Goal | Requirement |
|---|---|
| Simulator / Appetize testing | Nothing — works today |
| Installing on a physical iPhone | Free Apple ID + a Mac (7-day builds), or Apple Developer Program |
| TestFlight beta testing | Apple Developer Program ($99/year) |
| App Store release | Apple Developer Program + App Store review |
| Instant push notifications | Developer Program (APNs key) — see `Server/ADMIN-GUIDE.md`; background-refresh notifications already work without it |

See [ARCHITECTURE.md](ARCHITECTURE.md) for the technical deep-dive and the documented integration points (community feed endpoints, Instagram Graph API).
