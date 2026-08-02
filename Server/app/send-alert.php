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

$alertsFile = __DIR__ . '/alerts.json';

function yta_read_alerts(string $alertsFile): array
{
    $alerts = json_decode(@file_get_contents($alertsFile), true);
    return is_array($alerts) ? $alerts : [];
}

function yta_write_alerts(string $alertsFile, array $alerts): bool
{
    $handle = fopen($alertsFile, 'c+');
    if ($handle === false) {
        return false;
    }
    flock($handle, LOCK_EX);
    ftruncate($handle, 0);
    rewind($handle);
    fwrite($handle, json_encode($alerts, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
    fflush($handle);
    flock($handle, LOCK_UN);
    fclose($handle);
    return true;
}

/** Prepends a new entry to alerts.json. */
function yta_save_alert(string $alertsFile, string $title, string $message, string $severity, ?string $linkURL): array
{
    $entry = [
        'id' => 'alert-' . gmdate('Ymd-His') . '-' . bin2hex(random_bytes(3)),
        'title' => $title,
        'message' => $message,
        'severity' => $severity,
        'date' => gmdate('Y-m-d\TH:i:s\Z'),
        'linkURL' => $linkURL,
    ];
    $alerts = yta_read_alerts($alertsFile);
    array_unshift($alerts, $entry);
    return yta_write_alerts($alertsFile, $alerts) ? [true, null] : [false, 'Could not write alerts.json.'];
}

require __DIR__ . '/push-helper.php';

$result = null;

if (isset($_POST['action']) && $_POST['action'] === 'create') {
    $title = trim((string) $_POST['title']);
    $message = trim((string) $_POST['message']);
    $severity = in_array($_POST['severity'] ?? '', ['info', 'event', 'urgent'], true) ? $_POST['severity'] : 'info';
    $linkURL = trim((string) ($_POST['linkURL'] ?? ''));
    $linkURL = $linkURL === '' ? null : $linkURL;

    if ($title === '' || $message === '') {
        $result = ['ok' => false, 'error' => 'Title and message are both required.'];
    } else {
        [$alertOk, $alertError] = yta_save_alert($alertsFile, $title, $message, $severity, $linkURL);
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

if (isset($_POST['action']) && $_POST['action'] === 'delete' && isset($_POST['alertId'])) {
    $alertId = (string) $_POST['alertId'];
    $alerts = yta_read_alerts($alertsFile);
    $before = count($alerts);
    $alerts = array_values(array_filter($alerts, fn($a) => $a['id'] !== $alertId));

    if (count($alerts) === $before) {
        $result = ['ok' => false, 'error' => 'Alert not found (already deleted?).'];
    } else {
        $result = yta_write_alerts($alertsFile, $alerts)
            ? ['ok' => true, 'message' => 'Alert deleted.']
            : ['ok' => false, 'error' => 'Could not write alerts.json.'];
    }
}

$displayAlerts = yta_read_alerts($alertsFile);
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
      <div class="banner banner-success">✅ <?php echo htmlspecialchars($result['message'] ?? 'Alert published and push sent.'); ?></div>
    <?php else: ?>
      <div class="banner banner-error">⚠️ <?php echo htmlspecialchars($result['error']); ?></div>
    <?php endif; ?>
  <?php endif; ?>

  <form method="post">
    <input type="hidden" name="action" value="create">

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

  <hr class="divider">

  <h2 style="font-family:'Fraunces',serif;font-style:italic;font-size:18px;margin:0 0 16px;">Current alerts (<?php echo count($displayAlerts); ?>)</h2>

  <?php if (empty($displayAlerts)): ?>
    <p class="helper-text">No alerts yet.</p>
  <?php else: ?>
    <div class="results-list">
      <?php foreach ($displayAlerts as $alert): ?>
        <?php $severityColor = ['info' => '#16A34A', 'event' => '#C8951B', 'urgent' => '#DC2626'][$alert['severity']] ?? '#6B7280'; ?>
        <div class="result-item">
          <p class="result-question"><?php echo htmlspecialchars($alert['title']); ?></p>
          <p class="result-meta">
            <span style="color: <?php echo $severityColor; ?>; font-weight: 700;"><?php echo strtoupper(htmlspecialchars($alert['severity'])); ?></span>
            · <?php echo htmlspecialchars($alert['date']); ?>
          </p>
          <p class="result-meta" style="color:#374151;"><?php echo htmlspecialchars($alert['message']); ?></p>
          <form method="post" onsubmit="return confirm('Delete this alert? This cannot be undone.');" style="margin-top: 10px;">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="alertId" value="<?php echo htmlspecialchars($alert['id']); ?>">
            <button type="submit" class="btn-secondary" style="width: auto; padding: 8px 16px; font-size: 12px;">Delete</button>
          </form>
        </div>
      <?php endforeach; ?>
    </div>
  <?php endif; ?>
</div>
</body>
</html>
