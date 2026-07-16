# Release manifest — "Cinema of the Valley" redesign

## Wave 1.4 — live news feed + contact number update

**Added**

| File | Change |
|---|---|
| `YTA/Services/NewsStore.swift` | Press-tab state store mirroring `CommunityStore`'s pattern: remote fetch → disk cache → bundled seed, with `isRefreshing`/`isShowingCachedContent`/`lastSyncedAt` |
| `YTA/Views/Components/SyncStatusLabel.swift` | Freshness indicator extracted from `CommunityView` so Community and Press share one implementation |
| `YTA/Resources/Seed/news-seed.json` | The six launch articles, moved out of Swift source into bundled seed JSON (same role as `alerts-seed.json`/`polls-seed.json`) |
| `Server/app/news.json` | Ready-to-upload live news feed — mirrors the seed content, with `imageURL` pointing at the site's existing `assets/images/news/newsN.png` photos |

**Changed**

| File | Change |
|---|---|
| `YTA/Models/NewsArticle.swift` | Now `Codable`; dropped the hand-maintained `number` field (the Press tab computes display order from the article's position in the feed); `imageName` became optional and `imageURL: URL?` was added, so an article published later can use a remote photo — or none, falling back to a branded text-only card instead of a broken image |
| `YTA/Services/CommunityAPI.swift` | Added `fetchNews()` → `GET /app/news.json`; doc comment broadened from "community feed" to the association's full live content feed |
| `YTA/Services/ContentStore.swift` | Removed `newsArticles` (now owned by `NewsStore`); `pressIntro` (static framing copy) stays; contact phone number updated to **+961 3 871 077** |
| `YTA/Views/Press/PressView.swift` | Reads `NewsStore` instead of `ContentStore`; added pull-to-refresh, `SyncStatusLabel`, and image-fallback logic (bundled → remote → text-only) |
| `YTA/Views/Community/CommunityView.swift` | Its inline `syncStatus` replaced by the shared `SyncStatusLabel` |
| `YTA/App/YTAApp.swift` · `YTA/App/RootView.swift` | `NewsStore` created once and injected via `.environment(...)`, alongside `ContentStore`/`CommunityStore` |
| `Server/ADMIN-GUIDE.md` | Added "Publishing a news article" section; retitled to cover Alerts, Polls **and News** |

**Why:** the Press tab's six articles were hardcoded in `ContentStore` and compiled into the app binary — publishing a new one required a code change, a rebuild, and an App Store update. This wave gives YTA the same self-serve workflow already proven for alerts and polls: edit one JSON file on their own hosting, no developer and no app update needed.

## Wave 1.3 — client revisions (approved header artwork + removals)

**Added**

| File | Change |
|---|---|
| `YTA/Views/Components/YammounehHeroTransition.swift` | Reusable cinematic hero: parallax (image travels slower, stretches on overscroll), departure scrim, and a layered dissolve whose final stop is the exact section background token — no seam, no straight edge. Includes `JourneyAtmosphere` (faint gold haze + subtle tonal drift). Reduce Motion keeps the dissolve, drops all movement |
| `YTA/Assets.xcassets/yammouneh-header.imageset` | Client-approved Explore hero artwork (title embedded — not duplicated in SwiftUI) |
| `YTA/Assets.xcassets/community-header.imageset` | Client-approved Community header artwork (text embedded) |

**Changed**

| File | Change |
|---|---|
| `YTA/Theme/YTATheme.swift` | New shared token `ytaJourneyBackground` (#161C2E — sampled from the artwork's bottom edge); used by both the hero fade and the journey background |
| `YTA/Views/Gallery/GalleryView.swift` | Hero replaced by `YammounehHeroTransition` + scroll-linked parallax; refined floating season selector hangs into the transition zone; journey ground uses the shared token with `JourneyAtmosphere` |
| `YTA/Views/Community/CommunityView.swift` | Header is the approved artwork; segment control hangs into its teal wave |
| `YTA/Views/Connect/ConnectView.swift` | Banner rebuilt as a full-width hero dissolving into the screen background |
| `YTA/App/RootView.swift` | Media tab → Press (icon + title); shows PressView |
| `YTA/Views/Home/HeroSection.swift` · `YTA/Services/VideoLibrary.swift` | Welcome avatar removed |
| `YTA/Services/ContentStore.swift` · `YTA/Services/ExternalLinks.swift` | Instagram content removed (profile link kept in Connect) |

**Removed** — `WelcomeAvatar.swift`, `welcome-avatar.imageset`, `welcome-message.mp4`, `MediaView.swift`, `MediaHubView.swift`, `MediaViewModel.swift`, `InstagramPost.swift`

## Wave 1.2 — splash seam + real video keying + audio fix

| File | Change |
|---|---|
| `YTA/Assets.xcassets/splash-logo.imageset` *(added)* | The official logo pre-composed onto a pure-white circle (derived from `NGO LOGO.jpg`, nothing added) — eliminates the visible JPEG seam on the splash |
| `YTA/Views/Splash/SplashView.swift` | Uses the seamless composed asset; full logo always visible |
| `YTA/Views/Home/WelcomeAvatar.swift` | Real transparency: Core Image color-cube black-keying via an `AVMutableVideoComposition` (native equivalent of the website's canvas keyer) replaces the blend-mode approximation; audio session now set to `.playback` **and activated**, player explicitly unmuted — the welcome voice plays |

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
