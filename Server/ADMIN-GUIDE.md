# YTA App — Admin Guide (Alerts, Polls & News)

The app reads its live content from **your existing website hosting** — no new servers, no accounts, no monthly costs. You publish content by editing small text files.

## One-time setup (5 minutes)

1. In your Bluehost file manager (or FTP), go to the folder that serves `ytalebanon.org` (usually `public_html`).
2. Create a folder named `app`.
3. Upload everything inside `Server/app/` from this project:
   - `alerts.json` — the announcements feed
   - `polls.json` — the polls feed
   - `polls.php` — returns polls with live vote tallies
   - `vote.php` — records votes from the app
   - `news.json` — the Press tab's article feed
   - `events.json` — controls the home screen's "Upcoming Event" button
4. Verify: open `https://ytalebanon.org/app/alerts.json` in a browser — you should see the JSON.

That's it. The app checks these files on every launch, on pull-to-refresh, and periodically in the background.

## Sending an alert to all users

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

Users with the app open see it instantly on refresh; everyone else gets a quiet notification the next time iOS runs the app's background refresh (typically within a few hours). For *instant* push to locked phones, an Apple Push Notification server would be needed — see "Future upgrades" below.

## Creating a poll

Edit `app/polls.json` and add:

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
- To see results: open `https://ytalebanon.org/app/polls.php` in a browser.

## Publishing a news article

Edit `app/news.json` and add a new entry **at the top** (newest article first — the Press tab shows them in file order and numbers them automatically):

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

## Promoting an upcoming event

The hero screen's **"Upcoming Event"** button is only lit up (tappable) while `app/events.json` lists a current event. With an empty feed (`[]`, the default), the button is dimmed and does nothing — the app never advertises an event that isn't real.

To promote one, replace the file's contents with:

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
- `date` — ISO format, in UTC (`Z` suffix). Once this date/time passes, the button turns itself back off automatically — you don't need to remember to remove the entry. Use `null` to keep the promotion open-ended (stays on until you delete it).
- `linkURL` — where the button takes people: your event or ticket page. Use `null` to instead play the festival promo video already bundled in the app.

When you're done promoting, set the file back to `[]` (or delete the entry) and the button turns off.

## Push notifications — instant alerts to every user

Unlike everything above (which people see the next time they open the app), a push notification reaches every phone within seconds — locked, backgrounded, or app fully closed. It's powered by [OneSignal](https://onesignal.com), a free push service; no server of your own is needed.

### One-time setup (about 15 minutes, needs your Apple Developer account)

1. Create a free account at [onesignal.com](https://onesignal.com) and create a new app (platform: **Apple iOS (APNs)**). Name it "YTA Lebanon" or similar.
2. Generate an APNs key so OneSignal can talk to Apple on your behalf:
   - Sign in to [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles → Keys**.
   - Click **+**, name it "OneSignal Push", check **Apple Push Notifications service (APNs)**, then **Continue → Register**.
   - **Download the `.p8` file now** — Apple only lets you download it once. Also note the **Key ID** shown on that page, and your **Team ID** (top-right of the Apple Developer site, under your name).
3. Back in OneSignal: **Settings → Push & In-App → Apple iOS (APNs)** → upload the `.p8` file along with the Key ID and Team ID.
4. Still in OneSignal: **Settings → Keys & IDs** → copy the **OneSignal App ID** (a long string of letters and numbers).
5. Send that App ID to your developer to paste into `YTA/Services/OneSignalConfig.swift` (replacing the placeholder), then rebuild and resubmit the app. Push notifications silently do nothing until this step is done — nothing else in the app depends on it or breaks without it.
6. One Apple-side check: **developer.apple.com → Identifiers → org.ytalebanon.app** should have **Push Notifications** listed as an enabled capability (Xcode's automatic signing usually turns this on by itself the first time the app is archived for release; if the App Store build fails signing, this is the first thing to check).

### Sending a notification

1. Log in to [onesignal.com](https://onesignal.com) → your app → **Messages → New Push**.
2. Write a title and message — e.g. "Road closed for festival weekend" or "New poll: winter snowshoe festival?".
3. Leave **Audience** as **All Subscribed Users** (OneSignal's Segments feature can target more precisely later, if ever needed).
4. Click **Send**. It reaches every device with the app installed, typically within seconds.

### Notes

- The app already requests notification permission quietly (no popup) the first time it's opened, so most users are automatically subscribed without doing anything on their end.
- This is a separate channel from the in-app **Alerts** tab — sending a push *and* adding the same entry to `alerts.json` keeps both in sync, so anyone who missed the push still sees it the next time they open the app.

## Rules of thumb

- Always validate your edits at https://jsonlint.com before uploading — one missing comma breaks the feed (the app then falls back to its cached copy, so nothing crashes).
- Keep alerts and polls image-free by design — they load instantly on poor connections. News articles may include one photo.
- The app enforces one vote per device.

## Future upgrades (documented integration points)

| Want | Needs |
|---|---|
| Target a push at a subset of users (e.g. only people who opened Community before) | OneSignal's free Segments/Filters feature — no code change needed |
| Auto-send a push whenever `alerts.json` is edited, instead of sending manually | A small script triggered on upload (e.g. an FTP/cron hook) calling OneSignal's REST API |
| Vote fraud protection beyond per-device | Move `vote.php` logic behind an authenticated API. |
| An admin app instead of file editing | Point `CommunityAPI.baseURL` at any CMS that outputs the same JSON. |
