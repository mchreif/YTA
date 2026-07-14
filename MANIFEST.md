# Release manifest — "Cinema of the Valley" redesign

## Wave 1.1 — hero welcome avatar + review fixes

| File | Change |
|---|---|
| `YTA/Views/Home/WelcomeAvatar.swift` *(added)* | The website's hero welcome avatar, now native: tap the cut-out of Ali Chreif and his welcome message plays inline (screen-blend keying melts the clip's black backdrop into the dark hero), collapsing back on completion. Poster `welcome_avatar.png` + video `menhem-ios.mp4` are the site's own hero assets |
| `YTA/Assets.xcassets/welcome-avatar.imageset` *(added)* | Official poster cut-out (alpha preserved, never cropped) |
| `YTA/Resources/Videos/welcome-message.mp4` *(added)* | Official welcome video (site: menhem-ios.mp4, 1.8 MB) |
| `YTA/Services/VideoLibrary.swift` | Added `welcomeMessage` resolver |
| `YTA/Views/Home/HeroSection.swift` | Welcome avatar placed above the hero actions, trailing — as on the website |
| `YTA/Views/Splash/SplashView.swift` | Logo now fitted on a white circular plate — the full mark is visible, nothing cropped |
| `YTA/Views/Community/CommunityView.swift` | Header rebuilt as a cinematic scene banner (official festival-crowd photograph + serif title); cropped-logo mesh banner removed |

## Wave 1 — approved Direction B implementation

Design direction B, approved July 2026. All content, data, community feed,
networking, deep links, XcodeGen configuration and the CI workflow are
unchanged; this wave is presentation only. Every image referenced in code
is one of the 26 official YTA asset-catalog sets (verified — nothing stock,
generated, or placeholder was added).

## Added files (2)

| File | Purpose |
|---|---|
| `YTA/Views/Components/SceneComponents.swift` | The redesign's shared design language: SceneTitle (serif + gold rule headings), KenBurnsImage (cinematic push-in, Reduce Motion aware), SceneScrim, RouteConnector (gold route-line segments), AwaitingDataCard (honest missing-data state) |
| `YTA/Views/Gallery/AttractionDetailView.swift` | New attraction scene screen: iOS 18 zoom transition, Ken Burns hero → lightbox, official story text, Directions / Ask-a-guide / Share actions, related-scenes rail |

## Modified files (15)

| File | Change |
|---|---|
| `YTA/Views/Gallery/GalleryView.swift` | Rebuilt as the Explore journey: seasonal crossfading scene header, route-line journey through the six official scenes, filmstrip; PhotoLightbox made shared |
| `YTA/Models/GalleryPhoto.swift` | Added `ValleySeason` (presentation grouping) and `storyProgramID` (link to official mission text) |
| `YTA/Services/ContentStore.swift` | Gallery entries carry season + story links; added `seasonHero(for:)`, `program(withID:)`, `relatedPhotos(to:)` |
| `YTA/Services/ExternalLinks.swift` | Added shared `appleMapsURL(latitude:longitude:label:)` helper |
| `YTA/ViewModels/ConnectViewModel.swift` | Directions link now uses the shared helper |
| `YTA/Theme/YTATheme.swift` | Added `ytaNavyElevated` surface color |
| `YTA/Views/Home/MissionSection.swift` | SceneTitle header, serif card titles, honest "Next edition — date to be announced" state on the festivals card |
| `YTA/Views/Home/ImpactSection.swift` | SceneTitle header; verified counters now play over the official reforestation photograph |
| `YTA/Views/Home/BoardSection.swift` | SceneTitle header; added the closing "Plan Your Visit" banner (jumps to Connect) |
| `YTA/Views/Home/HomeView.swift` | Threads the new `onPlanVisit` action |
| `YTA/App/RootView.swift` | Provides `onPlanVisit` (switches to Connect) |
| `YTA/Views/Connect/ConnectView.swift` | Opens on a Natural Reserve scene banner |
| `YTA/Resources/Localizable.xcstrings` | +13 strings (EN source + Arabic; Arabic pending YTA review) |
| `README.md` | Explore feature description updated |
| `ARCHITECTURE.md` | Views/components documentation updated |

## Pre-flight verification (all passed)

1. Both new Swift files on disk; `project.yml` sources the whole `YTA/` folder, so they are in the target automatically
2. Scheme: `YTA`
3. Bundle identifier: `org.ytalebanon.app`
4. Localization catalog: 60 keys, 0 duplicates, valid JSON
5. Asset catalog: exactly the 26 official YTA imagesets — none added, none removed
6. Every image name referenced in Swift resolves to an official set
7. GitHub Actions workflow intact (macos-15, XcodeGen, unsigned simulator build, error reporting, artifacts)
8. Full validation: all JSON/plist parse, all 49 Swift files brace-balanced, system-framework imports only, no TODO/FIXME markers
