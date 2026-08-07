<?php
/**
 * "Upcoming Event" admin tool. The app only ever looks at the first
 * not-yet-passed entry in events.json (see EventsStore.swift /
 * EventsContext.tsx), so in practice this is a single on/off toggle
 * rather than a list — this page presents it that way instead of a
 * generic array editor.
 *
 * Shares config.local.php and the login session with send-alert.php /
 * manage-polls.php — see send-alert.php's header comment for setup.
 */
$config = @include __DIR__ . '/config.local.php';
if (!is_array($config) || empty($config['adminPassword'])) {
    http_response_code(500);
    echo 'Missing or incomplete config.local.php. Copy config.local.example.php to config.local.php in this folder and fill in real values.';
    exit;
}

require __DIR__ . '/auth-helper.php';
yta_require_admin_auth($config['adminPassword']);

require __DIR__ . '/push-helper.php';

$eventsFile = __DIR__ . '/events.json';

function yta_write_events(string $eventsFile, array $events): bool
{
    $handle = fopen($eventsFile, 'c+');
    if ($handle === false) {
        return false;
    }
    flock($handle, LOCK_EX);
    ftruncate($handle, 0);
    rewind($handle);
    fwrite($handle, json_encode($events, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
    fflush($handle);
    flock($handle, LOCK_UN);
    fclose($handle);
    return true;
}

$result = null;

if (isset($_POST['action']) && $_POST['action'] === 'activate') {
    $title = trim((string) ($_POST['title'] ?? ''));
    $date = trim((string) ($_POST['date'] ?? ''));
    $linkURL = trim((string) ($_POST['linkURL'] ?? ''));
    $linkURL = $linkURL === '' ? null : $linkURL;

    if ($title === '') {
        $result = ['ok' => false, 'error' => 'A title is required.'];
    } else {
        $dateValue = null;
        if ($date !== '') {
            $dt = DateTime::createFromFormat('Y-m-d\TH:i', $date, new DateTimeZone(date_default_timezone_get() ?: 'UTC'));
            if ($dt !== false) {
                $dt->setTimezone(new DateTimeZone('UTC'));
                $dateValue = $dt->format('Y-m-d\TH:i:s\Z');
            }
        }
        $events = [[
            'id' => 'event-' . gmdate('Ymd-His'),
            'title' => $title,
            'date' => $dateValue,
            'linkURL' => $linkURL,
        ]];
        if (!yta_write_events($eventsFile, $events)) {
            $result = ['ok' => false, 'error' => 'Could not write events.json.'];
        } else {
            $message = 'Upcoming Event button turned on.';
            if (!empty($_POST['sendPush'])) {
                [$pushOk, $pushError] = yta_send_push($config, 'Upcoming Event', $title);
                $message .= $pushOk ? ' Push sent.' : (' Push not sent: ' . $pushError);
            }
            $result = ['ok' => true, 'message' => $message];
        }
    }
}

if (isset($_POST['action']) && $_POST['action'] === 'deactivate') {
    $result = yta_write_events($eventsFile, [])
        ? ['ok' => true, 'message' => 'Upcoming Event button turned off.']
        : ['ok' => false, 'error' => 'Could not write events.json.'];
}

$events = json_decode(@file_get_contents($eventsFile), true);
if (!is_array($events)) {
    $events = [];
}
$activeEvent = null;
foreach ($events as $event) {
    $isCurrent = empty($event['date']) || strtotime($event['date']) > time();
    if ($isCurrent) {
        $activeEvent = $event;
        break;
    }
}
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>YTA Admin — Upcoming Event</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&family=Fraunces:ital,wght@0,600;1,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="admin-style.css">
</head>
<body>
<?php $currentPage = 'event'; include __DIR__ . '/admin-nav.php'; ?>
<div class="admin-card">
  <div class="admin-header">
    <img src="https://ytalebanon.org/assets/images/logos/yam.png" alt="YTA">
    <div>
      <p class="admin-eyebrow">YTA Admin</p>
      <h1>Upcoming Event</h1>
    </div>
  </div>
  <div class="gold-rule"></div>
  <p class="admin-lead">Controls the Home screen's "Upcoming Event" button — it only lights up while an event is active here.</p>

  <?php if ($result): ?>
    <?php if ($result['ok']): ?>
      <div class="banner banner-success">✅ <?php echo htmlspecialchars($result['message']); ?></div>
    <?php else: ?>
      <div class="banner banner-error">⚠️ <?php echo htmlspecialchars($result['error']); ?></div>
    <?php endif; ?>
  <?php endif; ?>

  <?php if ($activeEvent): ?>
    <div class="result-item" style="margin-bottom: 24px;">
      <p class="result-meta" style="margin-bottom: 8px;"><span class="status-open">● ACTIVE</span></p>
      <p class="result-question"><?php echo htmlspecialchars($activeEvent['title']); ?></p>
      <p class="result-meta">
        <?php echo !empty($activeEvent['date']) ? 'Until ' . htmlspecialchars($activeEvent['date']) : 'Open-ended'; ?>
        <?php if (!empty($activeEvent['linkURL'])): ?><br>Links to: <?php echo htmlspecialchars($activeEvent['linkURL']); ?><?php else: ?><br>No link set — button plays the bundled promo video instead.<?php endif; ?>
      </p>
    </div>
    <form method="post" onsubmit="return confirm('Turn off the Upcoming Event button?');">
      <input type="hidden" name="action" value="deactivate">
      <button type="submit" class="btn-secondary">Turn Off</button>
    </form>
  <?php else: ?>
    <div class="banner" style="background:#F3F4F6;color:#6B7280;">Currently <strong>off</strong> — the button is dimmed in the app.</div>

    <form method="post">
      <input type="hidden" name="action" value="activate">

      <div class="field">
        <label for="title">Event title</label>
        <input type="text" id="title" name="title" required maxlength="120" placeholder="e.g. Yammouneh Summer Festival">
      </div>

      <div class="field">
        <label for="date">Ends at (optional)</label>
        <input type="datetime-local" id="date" name="date">
        <p class="helper-text">The button turns itself off automatically after this. Leave blank to keep it on until you turn it off manually.</p>
      </div>

      <div class="field">
        <label for="linkURL">Link URL (optional)</label>
        <input type="url" id="linkURL" name="linkURL" placeholder="https://…">
        <p class="helper-text">Where the button takes people. Leave blank and it plays the bundled promo video instead.</p>
      </div>

      <div class="field">
        <label class="checkbox-row"><input type="checkbox" name="sendPush" value="1"> Also send a push notification to everyone</label>
      </div>

      <button type="submit">Turn On</button>
    </form>
  <?php endif; ?>
</div>
</body>
</html>
