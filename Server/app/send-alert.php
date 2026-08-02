<?php
/**
 * Combined "publish an alert + send the matching push" admin tool.
 *
 * Replaces doing these as two separate manual steps (editing alerts.json
 * by hand, then separately sending a push from OneSignal's dashboard):
 * this does both atomically from one small form, so anyone using it
 * never forgets one half or ends up with mismatched content.
 *
 * One-time setup: copy config.local.example.php to config.local.php in
 * this same folder and fill in the real OneSignal App ID, REST API Key,
 * and a password of your choosing. config.local.php is gitignored —
 * it holds real secrets and must never be committed or shared.
 */
session_start();

$config = @include __DIR__ . '/config.local.php';
if (!is_array($config) || empty($config['restApiKey']) || empty($config['adminPassword']) || empty($config['appId'])) {
    http_response_code(500);
    echo 'Missing or incomplete config.local.php. Copy config.local.example.php to config.local.php in this folder and fill in real values.';
    exit;
}

$authenticated = !empty($_SESSION['yta_admin_authed']);
$loginError = null;

if (!$authenticated && isset($_POST['password'])) {
    if (hash_equals($config['adminPassword'], (string) $_POST['password'])) {
        $_SESSION['yta_admin_authed'] = true;
        $authenticated = true;
    } else {
        $loginError = 'Incorrect password.';
    }
}

if (!$authenticated) {
    include __DIR__ . '/admin-login.php';
    exit;
}

/** Prepends the entry to alerts.json (lock for safe concurrent writes). */
function yta_save_alert(string $title, string $message, string $severity, ?string $linkURL): array
{
    $alertsFile = __DIR__ . '/alerts.json';
    $entry = [
        'id' => 'alert-' . gmdate('Ymd-His') . '-' . bin2hex(random_bytes(3)),
        'title' => $title,
        'message' => $message,
        'severity' => $severity,
        'date' => gmdate('Y-m-d\TH:i:s\Z'),
        'linkURL' => $linkURL,
    ];

    $handle = fopen($alertsFile, 'c+');
    if ($handle === false) {
        return [false, 'Could not open alerts.json for writing.'];
    }
    flock($handle, LOCK_EX);
    $raw = stream_get_contents($handle);
    $alerts = json_decode($raw, true);
    if (!is_array($alerts)) {
        $alerts = [];
    }
    array_unshift($alerts, $entry);
    ftruncate($handle, 0);
    rewind($handle);
    fwrite($handle, json_encode($alerts, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
    fflush($handle);
    flock($handle, LOCK_UN);
    fclose($handle);

    return [true, null];
}

require __DIR__ . '/push-helper.php';

$result = null;
if (isset($_POST['title'], $_POST['message'])) {
    $title = trim((string) $_POST['title']);
    $message = trim((string) $_POST['message']);
    $severity = in_array($_POST['severity'] ?? '', ['info', 'event', 'urgent'], true) ? $_POST['severity'] : 'info';
    $linkURL = trim((string) ($_POST['linkURL'] ?? ''));
    $linkURL = $linkURL === '' ? null : $linkURL;

    if ($title === '' || $message === '') {
        $result = ['ok' => false, 'error' => 'Title and message are both required.'];
    } else {
        [$alertOk, $alertError] = yta_save_alert($title, $message, $severity, $linkURL);
        if (!$alertOk) {
            $result = ['ok' => false, 'error' => $alertError];
        } else {
            [$pushOk, $pushError] = yta_send_push($config, $title, $message);
            $result = $pushOk
                ? ['ok' => true]
                : ['ok' => false, 'error' => 'Alert was published, but the push failed: ' . $pushError];
        }
    }
}
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>YTA Admin — Send Alert</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&family=Fraunces:ital,wght@0,600;1,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="admin-style.css">
</head>
<body>
<?php $currentPage = 'alerts'; include __DIR__ . '/admin-nav.php'; ?>
<div class="admin-card">
  <div class="admin-header">
    <img src="https://ytalebanon.org/assets/images/logos/yam.png" alt="YTA">
    <div>
      <p class="admin-eyebrow">YTA Admin</p>
      <h1>Send Alert</h1>
    </div>
  </div>
  <div class="gold-rule"></div>
  <p class="admin-lead">Publishes to the app's Alerts list <strong>and</strong> sends an instant push notification to every subscribed device, in one step.</p>

  <?php if ($result): ?>
    <?php if ($result['ok']): ?>
      <div class="banner banner-success">✅ Alert published and push sent.</div>
    <?php else: ?>
      <div class="banner banner-error">⚠️ <?php echo htmlspecialchars($result['error']); ?></div>
    <?php endif; ?>
  <?php endif; ?>

  <form method="post">
    <div class="field">
      <label for="title">Title</label>
      <input type="text" id="title" name="title" required maxlength="120" placeholder="e.g. Road closed for festival weekend">
    </div>

    <div class="field">
      <label for="message">Message</label>
      <textarea id="message" name="message" required maxlength="500" placeholder="The full message people will read"></textarea>
    </div>

    <div class="field">
      <label>Severity</label>
      <div class="pill-group">
        <input type="radio" id="sev-info" name="severity" value="info" checked>
        <label for="sev-info" class="severity-info">Info</label>
        <input type="radio" id="sev-event" name="severity" value="event">
        <label for="sev-event" class="severity-event">Event</label>
        <input type="radio" id="sev-urgent" name="severity" value="urgent">
        <label for="sev-urgent" class="severity-urgent">Urgent</label>
      </div>
      <p class="helper-text">Urgent alerts also play a sound.</p>
    </div>

    <div class="field">
      <label for="linkURL">Link URL (optional)</label>
      <input type="url" id="linkURL" name="linkURL" placeholder="https://…">
      <p class="helper-text">Adds a "Learn more" button in the app.</p>
    </div>

    <button type="submit">Publish &amp; Send Push</button>
  </form>
</div>
</body>
</html>
