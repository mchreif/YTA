# YTA App — Admin Guide (Alerts, Polls, News & Event)

The app reads its live content from **your existing website hosting** — no new servers, no accounts, no monthly costs. Four small admin pages let you publish everything from a browser, without hand-editing JSON.

## One-time setup (5 minutes)

1. In your Bluehost file manager (or FTP), go to the folder that serves `ytalebanon.org` (usually `public_html`).
2. Create a folder named `app`.
3. Upload everything inside `Server/app/` from this project:
   - `alerts.json`, `polls.json`, `news.json`, `events.json` — the live content feeds
   - `polls.php` — returns polls with live vote tallies
   - `vote.php` — records votes from the app
   - `admin-style.css`, `admin-login.php`, `admin-nav.php` — shared look, sign-in, and top navigation for the four admin tools below
   - `send-alert.php`, `manage-polls.php`, `manage-news.php`, `manage-event.php` — the admin tools themselves (see their sections below; `send-alert.php` needs a one-time `config.local.php` you create yourself — **never** upload real secrets from anywhere but your own server)
4. Verify: open `https://ytalebanon.org/app/alerts.json` in a browser — you should see the JSON.

That's it. The app checks these files on every launch, on pull-to-refresh, and periodically in the background. All four tools share one login — sign in once at any of them and a top nav bar (Alerts · Polls · News · Event) links between the rest.

## Sending an alert — `send-alert.php` (recommended)

Visit `https://ytalebanon.org/app/send-alert.php`, sign in, and fill in a title, message, severity (info/event/urgent), and an optional link. Publishing does two things at once: it adds the entry to `alerts.json` **and** sends an instant push notification to every subscribed device via OneSignal — one form, both steps, always in sync.

One-time setup: copy `config.local.example.php` to `config.local.php` in the same `app/` folder and fill in your OneSignal **App ID**, **REST API Key** (Settings → Keys & IDs in the OneSignal dashboard), and an admin password of your choosing. This file is gitignored and must never be committed or shared — it holds real secrets.

### Doing it by hand instead

Edit `app/alerts.json` and add a new entry **at the top**:

```json
{
  "id": "2026-road-closure",
  "title": "Road update for festival weekend",
  "message": "The Ainata road is closed Saturday morning — please arrive via Deir El Ahmar.",
  "severity": "urgent",
  "date": "2026-08-14T09:00:00Z",
  "linkURL": null
}
```

- `id` — any unique text; never reuse an old one (users would not be re-notified).
- `severity` — `info` (blue), `event` (gold), or `urgent` (red, plays a sound).
- `date` — ISO format, in UTC (`Z` suffix). Newest date shows first.
- `linkURL` — a web link for a "Learn more" button, or `null`.

Editing the file by hand does **not** send a push — pair it with a manual OneSignal send (see "Sending a notification without send-alert.php" below) if you want one.

## Creating a poll — `manage-polls.php` (recommended)

Visit `https://ytalebanon.org/app/manage-polls.php`, sign in, and fill in the question, optional details, an optional closing date, and 2–4 options. Publishing writes the poll to `polls.json` for you — no manual JSON editing. The same page shows a **live results dashboard** underneath (percentage bars, vote counts, open/closed status) for every existing poll, with a **Delete** button that also cleans up its recorded votes.

Tick **"Also send a push notification to everyone"** if you want this poll announced instantly, the same way `send-alert.php` does — left unchecked (the default), publishing stays quiet and only shows up next time someone opens the app.

### Doing it by hand instead

If you'd rather edit the file directly, add a new entry to `app/polls.json`:

```json
{
  "id": "2027-winter-event",
  "question": "Should YTA host a winter snowshoe festival?",
  "details": "A one-day event at the reserve with local food stalls.",
  "closesAt": "2026-12-15T21:00:00Z",
  "options": [
    { "id": "yes", "title": "Yes, every year", "votes": 0 },
    { "id": "once", "title": "Try it once first", "votes": 0 },
    { "id": "no", "title": "Focus on summer instead", "votes": 0 }
  ]
}
```

- `closesAt` — when voting ends (the app then shows final results and highlights the winner). Use `null` to keep it open forever.
- Start `votes` at `0`; `vote.php` adds real votes on top in `votes.json` (created automatically — don't edit it).
- To see raw results without `manage-polls.php`: open `https://ytalebanon.org/app/polls.php` in a browser (plain JSON, not a formatted page).

## Publishing a news article — `manage-news.php` (recommended)

Visit `https://ytalebanon.org/app/manage-news.php`, sign in, and fill in the title and summary (both typed right-to-left in Arabic), the article link, and an optional photo URL. Publishing adds it to `news.json` for you, newest first. The page also lists every existing article with a **Delete** button.

Tick **"Also send a push notification to everyone"** to announce the article instantly — left unchecked (the default), it just shows up next time someone opens the Press tab.

### Doing it by hand instead

Edit `app/news.json` and add a new entry **at the top** (newest article first):

```json
{
  "id": "n7",
  "title": "عنوان المقال بالعربية",
  "summary": "ملخص قصير للمقال بالعربية.",
  "imageName": null,
  "imageURL": "https://ytalebanon.org/assets/images/news/your-photo.png",
  "url": "https://example.com/the-full-article"
}
```

- `id` — any unique text you haven't used before.
- `title` / `summary` — the Arabic headline and short summary; the app displays them right-to-left automatically.
- `imageURL` — a link to any photo already hosted on your site (e.g. upload it next to the existing `assets/images/news/` photos and link to it there), or `null` for a clean text-only card — never leave it pointing at a broken link.
- `imageName` — leave as `null`; it's only used internally for the six articles that ship with the app.
- `url` — where "Read article" opens (the original press page, or a YouTube link, etc.).

Users see the new article the next time they open the Press tab or pull to refresh — no app update needed.

## Promoting an upcoming event — `manage-event.php` (recommended)

Visit `https://ytalebanon.org/app/manage-event.php` and sign in. The Home screen's **"Upcoming Event"** button only lights up while one event is active — this page presents it as a simple **on/off toggle** rather than a list, since the app only ever looks at the first event in the feed.

Fill in a title, an optional end date/time (the button turns itself off automatically once it passes — leave blank to keep it on until you turn it off manually), and an optional link (leave blank and it plays the bundled promo video instead). Tick **"Also send a push notification to everyone"** if you want to announce it instantly (only offered when turning the event *on* — turning it off never pushes). Click **Turn On**. When you're done promoting, come back and click **Turn Off**.

### Doing it by hand instead

Replace `app/events.json`'s contents with:

```json
[
  {
    "id": "2026-summer-festival",
    "title": "Yammouneh Summer Festival",
    "date": "2026-08-20T18:00:00Z",
    "linkURL": "https://ytalebanon.org/festival"
  }
]
```

- `id` — any unique text.
- `date` — ISO format, in UTC (`Z` suffix), or `null` to keep the promotion open-ended.
- `linkURL` — where the button takes people, or `null` to play the bundled promo video instead.

Set the file back to `[]` (or delete the entry) and the button turns off.

## Push notifications — how it works

Every alert sent through `send-alert.php` already triggers an instant push automatically. The other three tools (`manage-polls.php`, `manage-news.php`, `manage-event.php`) each have an optional **"Also send a push notification to everyone"** checkbox, unchecked by default — tick it only when you want that specific poll, article, or event announced instantly rather than just quietly showing up next time someone opens the app. All four use the same [OneSignal](https://onesignal.com)-powered channel, reaching every subscribed device — locked, backgrounded, or app fully closed — typically within seconds.

### One-time setup (about 15 minutes, needs your Apple Developer account)

1. Create a free account at [onesignal.com](https://onesignal.com) and create a new app (platform: **Apple iOS (APNs)**). Name it "YTA Lebanon" or similar.
2. Generate an APNs key so OneSignal can talk to Apple on your behalf:
   - Sign in to [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles → Keys**.
   - Click **+**, name it "OneSignal Push", check **Apple Push Notifications service (APNs)**, then **Continue → Register**.
   - **Download the `.p8` file now** — Apple only lets you download it once. Also note the **Key ID** shown on that page, and your **Team ID** (top-right of the Apple Developer site, under your name).
3. Back in OneSignal: **Settings → Push & In-App → Apple iOS (APNs)** → upload the `.p8` file along with the Key ID and Team ID.
4. Still in OneSignal: **Settings → Keys & IDs** → copy the **OneSignal App ID** and generate/copy a **REST API Key**. Both go into `config.local.php` (see the "Sending an alert" section above).
5. Send the App ID to your developer to paste into `YTA/Services/OneSignalConfig.swift` (replacing the placeholder), then rebuild and resubmit the app. Push notifications silently do nothing until this step is done — nothing else in the app depends on it or breaks without it.
6. One Apple-side check: **developer.apple.com → Identifiers → org.ytalebanon.app** should have **Push Notifications** listed as an enabled capability (Xcode's automatic signing usually turns this on by itself the first time the app is archived for release; if the App Store build fails signing, this is the first thing to check).

### Sending a notification without send-alert.php

If you ever want to send a push that *isn't* tied to a new alert (e.g. a poll reminder), you can still do it manually:

1. Log in to [onesignal.com](https://onesignal.com) → your app → **Messages → New Push**.
2. Write a title and message — e.g. "New poll: winter snowshoe festival?".
3. Leave **Audience** as **All Subscribed Users**.
4. Click **Send**.

### Notes

- The app already requests notification permission quietly (no popup) the first time it's opened, so most users are automatically subscribed without doing anything on their end.
- A manual push sent this way isn't automatically added to the in-app **Alerts** tab — use `send-alert.php` instead if you want both in sync.

## Rules of thumb

- If editing JSON by hand, always validate at https://jsonlint.com before uploading — one missing comma breaks the feed (the app then falls back to its cached copy, so nothing crashes).
- Keep alerts and polls image-free by design — they load instantly on poor connections. News articles may include one photo.
- The app enforces one vote per device.

## Future upgrades (documented integration points)

| Want | Needs |
|---|---|
| Target a push at a subset of users (e.g. only people who opened Community before) | OneSignal's free Segments/Filters feature — no code change needed |
| Vote fraud protection beyond per-device | Move `vote.php` logic behind an authenticated API. |
| An admin app instead of file editing | Point `CommunityAPI.baseURL` at any CMS that outputs the same JSON. |
