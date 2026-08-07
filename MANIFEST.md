# Release manifest — "Cinema of the Valley" redesign

## Wave 1.14 — fix flaky admin login; block directory listing on /app/

**Added**

| File | Change |
|---|---|
| `Server/app/auth-helper.php` | Extracted the session/password-check block (previously duplicated in all four admin tools) into a shared `yta_require_admin_auth()`. Sends explicit no-cache headers, and calls `session_regenerate_id(true)` immediately after a successful login |
| `Server/app/index.php` | Returns HTTP 403 with no content — visiting `https://ytalebanon.org/app/` bare no longer shows Apache's raw directory listing |
| `Server/app/.htaccess` | `Options -Indexes`, as a second layer in case `index.php` is ever missing |

**Changed**

| File | Change |
|---|---|
| `Server/app/send-alert.php`, `manage-polls.php`, `manage-news.php`, `manage-event.php` | Now call `yta_require_admin_auth()` instead of each having their own copy of the session/password-check logic |

**Why:** the admin login was intermittently rejecting the correct password with no error message, then working once a different admin tool was logged into first. Root cause: Bluehost runs an edge cache in front of Apache that caches `GET` responses (confirmed earlier via response headers in this project) but never `POST`. A first-time visitor's login-page load could be served a cached response, including whatever session cookie was baked into it at cache-time — shared across every visitor who hit that same cached copy, so a login could appear to succeed once and then get silently invalidated. `session_regenerate_id(true)` issues a guaranteed-fresh, private session ID on every successful login (served fresh, since POST is never cached), which resolves this regardless of the cache's exact behavior — and is standard security best practice on its own regardless of the caching angle.

**Verified:** confirmed via cookie tracking against an isolated test server that the session ID changes between the pre-login request and the post-login response, that the authenticated page renders immediately (not another login bounce), and that the new session is correctly recognized across a *different* admin tool without re-authenticating. Confirmed `/app/` now returns HTTP 403 with no listing. `php -l` passes clean on all six touched/added files.

## Wave 1.13 — delete alerts from send-alert.php

**Changed**

| File | Change |
|---|---|
| `Server/app/send-alert.php` | Added a "Current alerts" list underneath the publish form, each with a **Delete** button — matching the pattern already on `manage-polls.php`/`manage-news.php`. Refactored the inline alert-saving logic into shared `yta_read_alerts()`/`yta_write_alerts()` helpers so create and delete share the same read/write path. The create form's POST now carries an explicit `action=create` field (previously inferred from the presence of `title`/`message`), matching the `action`-based dispatch already used by the other three tools |
| `Server/ADMIN-GUIDE.md` | Notes that `send-alert.php` now lists and can delete existing alerts |

**Why:** `send-alert.php` was the only one of the four admin tools with no way to remove a published entry — deleting an alert required manually editing `alerts.json` via Bluehost's File Manager, unlike Polls/News which already had a Delete button.

**Verified:** tested the full create → list → delete cycle against an isolated PHP server — confirmed the new alert appears in the listing immediately after publishing, deleting it removes exactly that entry from `alerts.json`, and `php -l` passes clean.

## Wave 1.12 — fix: pushes were silently reaching nobody

**Changed**

| File | Change |
|---|---|
| `Server/app/push-helper.php` | Fixed `included_segments` from `'Subscribed Users'` (a segment name that doesn't exist on this OneSignal app) to `'Total Subscriptions'`; added response-body validation so an HTTP 200 that actually contains OneSignal's `{"id":"","errors":[...]}` "sent to nobody" shape is now correctly reported as a failure instead of a false "Push sent" |

**Why:** every push sent through any of the four admin tools was reporting success (`Push sent.`) while OneSignal silently delivered it to zero devices. Root-caused via OneSignal's read-only Notifications/Segments APIs: this app was created under OneSignal's newer "Subscriptions" model, whose default everyone-segment is named `Total Subscriptions` — the older `Subscribed Users` name (used in OneSignal's own REST API examples, and copied into `push-helper.php` originally) doesn't exist here, so OneSignal's API returned HTTP 200 with an empty `id` and `"errors":["All included players are not subscribed"]` every single time, which the code wasn't checking for.

**Verified:** confirmed live against the real OneSignal app (with the user's explicit go-ahead, since this fired real test pushes) — the old segment name reproduced the exact silent-failure response, the corrected segment name returned a valid message `id` and the notification was confirmed received on a real device, and the new response-validation logic was unit-tested against both captured response bodies.

## Wave 1.11 — optional push notifications for Polls, News, and Event

**Added**

| File | Change |
|---|---|
| `Server/app/push-helper.php` | Extracted `yta_send_push()` (OneSignal REST API call) out of `send-alert.php` into a shared helper, so it can be reused by the other three admin tools without duplicating the cURL/error-handling logic |

**Changed**

| File | Change |
|---|---|
| `Server/app/send-alert.php` | Now `require`s `push-helper.php` instead of defining its own copy of `yta_send_push()` — no behavior change |
| `Server/app/manage-polls.php` | Added an optional "Also send a push notification to everyone" checkbox (unchecked by default) to the create-poll form; when ticked, sends a push (heading "New Poll", body = the poll question) after the poll saves successfully |
| `Server/app/manage-news.php` | Same optional checkbox on the publish-article form; push heading/body use the article's own title/summary |
| `Server/app/manage-event.php` | Same optional checkbox, offered only on the "Turn On" form (never on "Turn Off" — nobody wants a push announcing an event ended) |
| `Server/app/admin-style.css` | Added `.checkbox-row` styling (green accent-color checkbox in a bordered pill row) shared by the three new checkboxes |
| `Server/ADMIN-GUIDE.md` | Documents the new checkbox in each of the Polls/News/Event sections, and reworded the "Push notifications" section to reflect that all four tools now share the same OneSignal channel |

**Why:** previously only `send-alert.php` could send a push — publishing a poll, article, or event promotion never notified anyone beyond the in-app feed, even though those are sometimes just as time-sensitive as an alert. Made it opt-in and off-by-default rather than automatic, since auto-pushing on every routine publish risks notification fatigue; staff decide per item whether it's worth an interruption.

**Verified:** tested all three checkboxes end-to-end against an isolated PHP server with fake data — confirmed (a) the checked path attempts a push and reports success/failure without ever blocking the underlying save, (b) the unchecked (default) path never attempts a push at all, and (c) `php -l` passes clean on all five touched/added files.

## Wave 1.10 — branded admin tool suite (Alerts, Polls, News, Event)

**Added**

| File | Change |
|---|---|
| `Server/app/admin-style.css` | Shared branded stylesheet for all four admin tools — brand green/gold/navy tokens, Outfit + Fraunces fonts, mobile-responsive, custom pill-styled radio buttons, results/vote-bar styles |
| `Server/app/admin-nav.php` | Shared top navigation bar (Alerts · Polls · News · Event) included by all four tools, with active-page highlighting |
| `Server/app/manage-polls.php` | Create a poll (question, details, closing date, 2–4 options) from a form; live results dashboard with percentage bars underneath; Delete also cleans up `votes.json` |
| `Server/app/manage-news.php` | Publish a Press article (Arabic title/summary typed right-to-left, article link, optional photo URL) from a form; lists existing articles with Delete |
| `Server/app/manage-event.php` | Toggle-style control for the Home screen's "Upcoming Event" button (Turn On with title/end-date/link, or Turn Off) — matches the app's actual "first non-expired entry" runtime behavior instead of presenting a generic list editor |

**Changed**

| File | Change |
|---|---|
| `Server/app/send-alert.php` | Restyled to match the new shared design system; now includes the shared top nav instead of a single cross-link |
| `Server/ADMIN-GUIDE.md` | Rewritten so all four admin tools (not just polls) are documented as the recommended path, each with a "doing it by hand instead" fallback; push-notification section clarified now that `send-alert.php` sends the push automatically |

**Why:** alerts, polls, news, and the event promotion were four different workflows with inconsistent editing paths (some via forms, some via hand-edited JSON only). One consistent branded suite, sharing a single login and navigation bar, means non-technical YTA staff can manage all live app content from a browser without ever touching a JSON file or risking a syntax error that breaks the feed.

**Note:** `polls.json`/`votes.json`/`polls.php`/`vote.php` remain the live endpoints the app itself calls — `manage-polls.php` reads/writes the same files but is only ever visited by a human, never called by the app.

## Wave 1.9 — instant push notifications (OneSignal)

**Added**

| File | Change |
|---|---|
| `YTA/Services/OneSignalConfig.swift` | Holds the OneSignal App ID (ships as a placeholder — see "Configuration required" below) |
| `YTA/App/AppDelegate.swift` | Initializes the OneSignal SDK at launch (skipped no-op while the App ID is still the placeholder) |

**Changed**

| File | Change |
|---|---|
| `project.yml` | Added the `OneSignal-XCFramework` Swift Package (product `OneSignalFramework`); added a generated `YTA.entitlements` (`aps-environment`) |
| `Config/Info.plist` | `UIBackgroundModes` gained `remote-notification` alongside the existing `fetch` |
| `YTA/App/YTAApp.swift` | Wired `AppDelegate` in via `@UIApplicationDelegateAdaptor` (SwiftUI's `App` protocol has no launch hook of its own — OneSignal needs one) |
| `.github/workflows/ios-simulator-build.yml` | Added an explicit "Resolve Swift package dependencies" step so a package-resolution failure shows clearly in CI logs instead of being buried inside the build step |
| `Server/ADMIN-GUIDE.md` | New "Push notifications" section: full OneSignal + APNs key setup walkthrough and how to send a push; removed the now-obsolete "future upgrade" row |
| `README.md`, `ARCHITECTURE.md` | Updated to describe the push channel alongside the existing background-refresh notifications |

**Why:** the existing background-refresh notifications can lag by hours (iOS decides when `BGAppRefreshTask` runs) or never fire if the app was force-quit. OneSignal gives YTA staff a dashboard where sending a push reaches every installed device — locked, backgrounded, or closed — within seconds, without requiring any server infrastructure beyond their existing Bluehost hosting.

**Configuration required before this works — none of it is something Claude can do on the user's behalf:**
1. Create a free OneSignal account and app.
2. Generate an APNs auth key in the Apple Developer portal and upload it to OneSignal.
3. Copy the OneSignal App ID into `YTA/Services/OneSignalConfig.swift`, replacing `REPLACE_WITH_ONESIGNAL_APP_ID`.

Full step-by-step is in `Server/ADMIN-GUIDE.md` → "Push notifications — instant alerts to every user". Until step 3 is done, `AppDelegate` intentionally no-ops — the rest of the app is unaffected.

**Known overlap:** the existing background-refresh local notifications (Wave-1 era, `CommunityBackgroundRefresh`) still run independently of this push channel. If both happen to fire for the same alert, a user could see two notifications instead of one. Left as-is for now since it's a minor, self-resolving overlap (not a crash or data issue) — worth revisiting only if it turns out to bother users in practice.

## Wave 1.8 — live-gated "Upcoming Event" button + new App Store icon

**Added**

| File | Change |
|---|---|
| `YTA/Models/UpcomingEvent.swift` | New model: `id`, `title`, optional `date`, optional `linkURL`. `isCurrent` ignores past-dated entries automatically |
| `YTA/Services/EventsStore.swift` | New store mirroring `NewsStore`'s pattern exactly: remote fetch → disk cache → bundled seed. `hasUpcomingEvent` drives the hero button's enabled state |
| `YTA/Resources/Seed/events-seed.json` | Bundled seed ships **empty** (`[]`) on purpose — until YTA publishes a real event, the button stays honestly disabled instead of always promoting a generic promo |
| `Server/app/events.json` | Ready-to-upload live feed, also empty by default; admin adds an entry to switch the button on |

**Changed**

| File | Change |
|---|---|
| `YTA/Services/CommunityAPI.swift` | Added `fetchEvents()` → `GET /app/events.json` |
| `YTA/Views/Home/HeroSection.swift` | Added `isUpcomingEventActive`; the "Upcoming Event" button is now `.disabled(...)`, dimmed to 45% opacity, and its gold pulse stops while there's nothing to promote |
| `YTA/Views/Components/YTAButtonStyles.swift` | `GoldPulse`/`goldPulse()` takes an `isActive` flag so callers can suppress the glow on a disabled button |
| `YTA/Views/Home/HomeView.swift` | Reads `EventsStore`; loads it on appear; tapping "Upcoming Event" now opens the published `linkURL` if YTA set one, otherwise falls back to the bundled festival promo video (unchanged behavior) |
| `YTA/App/YTAApp.swift` · `YTA/App/RootView.swift` | `EventsStore` created once and injected via `.environment(...)`, alongside the other live-content stores |
| `YTA/Assets.xcassets/AppIcon.appiconset/AppIcon.png` | New App Store icon: the official YAM brushstroke mark (text-free), recomposed centered on a diagonal navy-to-cedar-green gradient matching the app's brand palette. 1024×1024, no alpha channel (Apple requirement) — the previous version had the mark cropped off-center on a pale, low-contrast background |
| `Server/ADMIN-GUIDE.md` | Added "Promoting an upcoming event" section |

**Why:** the "Upcoming Event" button previously always played a bundled promo video regardless of whether YTA had anything scheduled. It now reflects reality — enabled only while a live event is published — using the same self-serve JSON pattern already proven for alerts, polls and news. The icon redesign fixes a real App Store presentation issue: the old crop was off-center and low-contrast on home screens.

**Behavior change to be aware of:** immediately after this update ships, the button will show as disabled (nothing is published in `events.json` yet) until YTA uploads an entry per the new admin-guide section.

## Wave 1.7 — App Store readiness: privacy manifest

**Added**

| File | Change |
|---|---|
| `YTA/PrivacyInfo.xcprivacy` | Declares the app's use of `UserDefaults` (reason `CA92.1` — reading/writing only the app's own data, for alert-read tracking and poll votes) under Apple's required-reason API disclosure rules. No tracking, no data collection declared (the app has neither). Audited against the actual codebase: no file-timestamp, disk-space, or other required-reason APIs are used |

**Why:** Apple requires a privacy manifest for apps that use certain "required reason" APIs; without one, App Store Connect can reject a submission at upload or during review. This was the one real gap found in an App Store readiness audit — everything else (single 1024×1024 App Store icon, `ITSAppUsesNonExemptEncryption` already set, no camera/photo/location APIs used) was already in order.

## Wave 1.6 — clean community photo + native title treatment

**Changed**

| File | Change |
|---|---|
| `YTA/Assets.xcassets/community-header.imageset` | Replaced with the text-free version of the same sunrise/hikers photo (client asked for the title to be drawn natively instead of baked into the artwork) |
| `YTA/Views/Community/CommunityView.swift` | The hero now draws its own title — a gold uppercase eyebrow ("Alerts & Project Updates") over a large serif display title ("Community") — using the exact same font sizes, kerning and drop-shadow treatment as the Explore journey's original title block |

## Wave 1.5 — Community hero matches the Explore treatment

**Changed**

| File | Change |
|---|---|
| `YTA/Assets.xcassets/community-header.imageset` | Replaced with the client-approved sunrise/hikers photo (title, URL and subtitle baked in); re-encoded from an 8.2 MB PNG to an 841 KB JPEG (same visual quality) |
| `YTA/Views/Community/CommunityView.swift` | The header is no longer a static rounded card — it's now `YammounehHeroTransition`, the exact same full-bleed cinematic component used by the Explore journey: scroll-linked parallax, slow push-in, and a layered dissolve into the screen's own `.ytaBackground` (no seam, no straight edge). The Alerts/Polls segment control now hangs into the fade zone the same way the Explore journey's season switcher does |

**Why:** the Community header previously sat in a separate rounded card below the status bar, breaking the cinematic language established for Explore. It now opens exactly like Explore does — full width, extending under the status bar, motion and all.

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
