<?php
/**
 * Poll admin tool: create a new poll, view live results, or delete one —
 * all from one page, so nobody needs to hand-edit polls.json.
 *
 * `polls.json` / `votes.json` / `polls.php` / `vote.php` are the live
 * endpoints the apps actually call — this page reads/writes the same
 * files but is never called by the app itself, only visited by a human.
 *
 * Shares config.local.php and the login session with send-alert.php —
 * see that file's header comment for one-time setup.
 */
session_start();

$config = @include __DIR__ . '/config.local.php';
if (!is_array($config) || empty($config['adminPassword'])) {
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

$pollsFile = __DIR__ . '/polls.json';
$votesFile = __DIR__ . '/votes.json';

/** Reads polls.json, tolerating a missing/empty file. */
function yta_read_polls(string $pollsFile): array
{
    $polls = json_decode(@file_get_contents($pollsFile), true);
    return is_array($polls) ? $polls : [];
}

/** Locked write-back to polls.json, matching vote.php's concurrency pattern. */
function yta_write_polls(string $pollsFile, array $polls): bool
{
    $handle = fopen($pollsFile, 'c+');
    if ($handle === false) {
        return false;
    }
    flock($handle, LOCK_EX);
    ftruncate($handle, 0);
    rewind($handle);
    fwrite($handle, json_encode($polls, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
    fflush($handle);
    flock($handle, LOCK_UN);
    fclose($handle);
    return true;
}

$result = null;

// Create a new poll.
if (isset($_POST['action']) && $_POST['action'] === 'create') {
    $question = trim((string) ($_POST['question'] ?? ''));
    $details = trim((string) ($_POST['details'] ?? ''));
    $closesAt = trim((string) ($_POST['closesAt'] ?? ''));
    $optionInputs = $_POST['options'] ?? [];
    $options = [];
    foreach ($optionInputs as $i => $text) {
        $text = trim((string) $text);
        if ($text === '') {
            continue;
        }
        $options[] = [
            'id' => 'opt-' . ($i + 1) . '-' . substr(bin2hex(random_bytes(2)), 0, 4),
            'title' => $text,
            'votes' => 0,
        ];
    }

    if ($question === '' || count($options) < 2) {
        $result = ['ok' => false, 'error' => 'A question and at least two options are required.'];
    } else {
        $closesAtValue = null;
        if ($closesAt !== '') {
            // <input type="datetime-local"> gives "YYYY-MM-DDTHH:MM" in the
            // visitor's local time; stored as UTC to match the app's format.
            $dt = DateTime::createFromFormat('Y-m-d\TH:i', $closesAt, new DateTimeZone(date_default_timezone_get() ?: 'UTC'));
            if ($dt !== false) {
                $dt->setTimezone(new DateTimeZone('UTC'));
                $closesAtValue = $dt->format('Y-m-d\TH:i:s\Z');
            }
        }

        $polls = yta_read_polls($pollsFile);
        array_unshift($polls, [
            'id' => 'poll-' . gmdate('Ymd-His') . '-' . bin2hex(random_bytes(3)),
            'question' => $question,
            'details' => $details,
            'closesAt' => $closesAtValue,
            'options' => $options,
        ]);

        $result = yta_write_polls($pollsFile, $polls)
            ? ['ok' => true, 'message' => 'Poll published.']
            : ['ok' => false, 'error' => 'Could not write polls.json.'];
    }
}

// Delete a poll.
if (isset($_POST['action']) && $_POST['action'] === 'delete' && isset($_POST['pollId'])) {
    $pollId = (string) $_POST['pollId'];
    $polls = yta_read_polls($pollsFile);
    $before = count($polls);
    $polls = array_values(array_filter($polls, fn($p) => $p['id'] !== $pollId));

    if (count($polls) === $before) {
        $result = ['ok' => false, 'error' => 'Poll not found (already deleted?).'];
    } elseif (!yta_write_polls($pollsFile, $polls)) {
        $result = ['ok' => false, 'error' => 'Could not write polls.json.'];
    } else {
        // Clean up its vote tallies too, so votes.json doesn't accumulate orphans.
        $votes = json_decode(@file_get_contents($votesFile), true);
        if (is_array($votes) && isset($votes[$pollId])) {
            unset($votes[$pollId]);
            $vh = fopen($votesFile, 'c+');
            if ($vh !== false) {
                flock($vh, LOCK_EX);
                ftruncate($vh, 0);
                rewind($vh);
                fwrite($vh, json_encode($votes, JSON_PRETTY_PRINT));
                fflush($vh);
                flock($vh, LOCK_UN);
                fclose($vh);
            }
        }
        $result = ['ok' => true, 'message' => 'Poll deleted.'];
    }
}

// Live results for display (same merge logic as polls.php).
$displayPolls = yta_read_polls($pollsFile);
$votes = json_decode(@file_get_contents($votesFile), true);
if (!is_array($votes)) {
    $votes = [];
}
foreach ($displayPolls as $pi => $poll) {
    foreach ($poll['options'] as $oi => $option) {
        $extra = $votes[$poll['id']][$option['id']] ?? 0;
        $displayPolls[$pi]['options'][$oi]['votes'] = $option['votes'] + $extra;
    }
}
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>YTA Admin — Manage Polls</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&family=Fraunces:ital,wght@0,600;1,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="admin-style.css">
</head>
<body>
<div class="admin-card">
  <div class="admin-header">
    <img src="https://ytalebanon.org/assets/images/logos/yam.png" alt="YTA">
    <div>
      <p class="admin-eyebrow">YTA Admin</p>
      <h1>Manage Polls</h1>
    </div>
  </div>
  <div class="gold-rule"></div>
  <p class="admin-lead">Create a new poll, or review live results below.</p>

  <?php if ($result): ?>
    <?php if ($result['ok']): ?>
      <div class="banner banner-success">✅ <?php echo htmlspecialchars($result['message']); ?></div>
    <?php else: ?>
      <div class="banner banner-error">⚠️ <?php echo htmlspecialchars($result['error']); ?></div>
    <?php endif; ?>
  <?php endif; ?>

  <form method="post">
    <input type="hidden" name="action" value="create">

    <div class="field">
      <label for="question">Question</label>
      <input type="text" id="question" name="question" required maxlength="160" placeholder="e.g. Which project should YTA prioritize next?">
    </div>

    <div class="field">
      <label for="details">Details (optional)</label>
      <textarea id="details" name="details" maxlength="300" placeholder="One sentence of context for voters"></textarea>
    </div>

    <div class="field">
      <label for="closesAt">Closes at (optional)</label>
      <input type="datetime-local" id="closesAt" name="closesAt">
      <p class="helper-text">Leave blank to keep the poll open indefinitely.</p>
    </div>

    <div class="field">
      <label>Options (at least 2)</label>
      <div class="option-row"><input type="text" name="options[]" maxlength="80" placeholder="Option 1"></div>
      <div class="option-row"><input type="text" name="options[]" maxlength="80" placeholder="Option 2"></div>
      <div class="option-row"><input type="text" name="options[]" maxlength="80" placeholder="Option 3 (optional)"></div>
      <div class="option-row"><input type="text" name="options[]" maxlength="80" placeholder="Option 4 (optional)"></div>
    </div>

    <button type="submit">Publish Poll</button>
  </form>

  <hr class="divider">

  <h2 style="font-family:'Fraunces',serif;font-style:italic;font-size:18px;margin:0 0 16px;">Current polls</h2>

  <?php if (empty($displayPolls)): ?>
    <p class="helper-text">No polls yet.</p>
  <?php else: ?>
    <div class="results-list">
      <?php foreach ($displayPolls as $poll): ?>
        <?php
          $total = array_sum(array_column($poll['options'], 'votes'));
          $isOpen = empty($poll['closesAt']) || strtotime($poll['closesAt']) > time();
        ?>
        <div class="result-item">
          <p class="result-question"><?php echo htmlspecialchars($poll['question']); ?></p>
          <p class="result-meta">
            <span class="<?php echo $isOpen ? 'status-open' : 'status-closed'; ?>"><?php echo $isOpen ? 'OPEN' : 'CLOSED'; ?></span>
            · <?php echo $total; ?> votes
            <?php if (!empty($poll['closesAt'])): ?> · closes <?php echo htmlspecialchars($poll['closesAt']); ?><?php endif; ?>
          </p>
          <?php foreach ($poll['options'] as $option): ?>
            <?php $pct = $total > 0 ? round(($option['votes'] / $total) * 100) : 0; ?>
            <div class="result-bar-row">
              <div class="result-bar-label"><span><?php echo htmlspecialchars($option['title']); ?></span><span><?php echo $pct; ?>%</span></div>
              <div class="result-bar-track"><div class="result-bar-fill" style="width: <?php echo $pct; ?>%;"></div></div>
            </div>
          <?php endforeach; ?>
          <form method="post" onsubmit="return confirm('Delete this poll? This cannot be undone.');" style="margin-top: 14px;">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="pollId" value="<?php echo htmlspecialchars($poll['id']); ?>">
            <button type="submit" class="btn-secondary" style="width: auto; padding: 8px 16px; font-size: 12px;">Delete</button>
          </form>
        </div>
      <?php endforeach; ?>
    </div>
  <?php endif; ?>

  <a class="top-link" href="send-alert.php">Send an alert instead →</a>
</div>
</body>
</html>
