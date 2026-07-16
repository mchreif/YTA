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

## Rules of thumb

- Always validate your edits at https://jsonlint.com before uploading — one missing comma breaks the feed (the app then falls back to its cached copy, so nothing crashes).
- Keep alerts and polls image-free by design — they load instantly on poor connections. News articles may include one photo.
- The app enforces one vote per device.

## Future upgrades (documented integration points)

| Want | Needs |
|---|---|
| Instant push notifications to locked phones | An APNs key (Apple Developer account) + a small push service, or a provider like OneSignal/Firebase. The app's `NotificationManager` is where device-token registration would go. |
| Vote fraud protection beyond per-device | Move `vote.php` logic behind an authenticated API. |
| An admin app instead of file editing | Point `CommunityAPI.baseURL` at any CMS that outputs the same JSON. |
