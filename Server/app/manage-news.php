<?php
/**
 * Press-article admin tool: publish a new article or delete one, without
 * hand-editing news.json. Articles are Arabic-language press coverage,
 * so the title/summary fields are RTL-aware for easier typing.
 *
 * Shares config.local.php and the login session with send-alert.php /
 * manage-polls.php — see send-alert.php's header comment for setup.
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

require __DIR__ . '/push-helper.php';

$newsFile = __DIR__ . '/news.json';

function yta_read_news(string $newsFile): array
{
    $news = json_decode(@file_get_contents($newsFile), true);
    return is_array($news) ? $news : [];
}

function yta_write_news(string $newsFile, array $news): bool
{
    $handle = fopen($newsFile, 'c+');
    if ($handle === false) {
        return false;
    }
    flock($handle, LOCK_EX);
    ftruncate($handle, 0);
    rewind($handle);
    fwrite($handle, json_encode($news, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
    fflush($handle);
    flock($handle, LOCK_UN);
    fclose($handle);
    return true;
}

$result = null;

if (isset($_POST['action']) && $_POST['action'] === 'create') {
    $title = trim((string) ($_POST['title'] ?? ''));
    $summary = trim((string) ($_POST['summary'] ?? ''));
    $url = trim((string) ($_POST['url'] ?? ''));
    $imageURL = trim((string) ($_POST['imageURL'] ?? ''));
    $imageURL = $imageURL === '' ? null : $imageURL;

    if ($title === '' || $summary === '' || $url === '') {
        $result = ['ok' => false, 'error' => 'Title, summary, and article link are all required.'];
    } elseif (!filter_var($url, FILTER_VALIDATE_URL)) {
        $result = ['ok' => false, 'error' => 'The article link doesn\'t look like a valid URL.'];
    } else {
        $news = yta_read_news($newsFile);
        array_unshift($news, [
            'id' => 'n-' . gmdate('Ymd-His') . '-' . bin2hex(random_bytes(3)),
            'title' => $title,
            'summary' => $summary,
            'imageName' => null,
            'imageURL' => $imageURL,
            'url' => $url,
        ]);
        if (!yta_write_news($newsFile, $news)) {
            $result = ['ok' => false, 'error' => 'Could not write news.json.'];
        } else {
            $message = 'Article published.';
            if (!empty($_POST['sendPush'])) {
                [$pushOk, $pushError] = yta_send_push($config, $title, $summary);
                $message .= $pushOk ? ' Push sent.' : (' Push not sent: ' . $pushError);
            }
            $result = ['ok' => true, 'message' => $message];
        }
    }
}

if (isset($_POST['action']) && $_POST['action'] === 'delete' && isset($_POST['articleId'])) {
    $articleId = (string) $_POST['articleId'];
    $news = yta_read_news($newsFile);
    $before = count($news);
    $news = array_values(array_filter($news, fn($a) => $a['id'] !== $articleId));

    if (count($news) === $before) {
        $result = ['ok' => false, 'error' => 'Article not found (already deleted?).'];
    } else {
        $result = yta_write_news($newsFile, $news)
            ? ['ok' => true, 'message' => 'Article deleted.']
            : ['ok' => false, 'error' => 'Could not write news.json.'];
    }
}

$displayNews = yta_read_news($newsFile);
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>YTA Admin — Manage News</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&family=Fraunces:ital,wght@0,600;1,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="admin-style.css">
</head>
<body>
<?php $currentPage = 'news'; include __DIR__ . '/admin-nav.php'; ?>
<div class="admin-card">
  <div class="admin-header">
    <img src="https://ytalebanon.org/assets/images/logos/yam.png" alt="YTA">
    <div>
      <p class="admin-eyebrow">YTA Admin</p>
      <h1>Manage News</h1>
    </div>
  </div>
  <div class="gold-rule"></div>
  <p class="admin-lead">Publishes to the Press tab. Titles and summaries are Arabic, shown right-to-left in the app automatically.</p>

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
      <label for="title">Title (Arabic)</label>
      <input type="text" id="title" name="title" dir="rtl" required maxlength="200" placeholder="عنوان المقال بالعربية">
    </div>

    <div class="field">
      <label for="summary">Summary (Arabic)</label>
      <textarea id="summary" name="summary" dir="rtl" required maxlength="400" placeholder="ملخص قصير للمقال بالعربية"></textarea>
    </div>

    <div class="field">
      <label for="url">Article link</label>
      <input type="url" id="url" name="url" required placeholder="https://… (the original press page, or a YouTube link, etc.)">
    </div>

    <div class="field">
      <label for="imageURL">Photo URL (optional)</label>
      <input type="url" id="imageURL" name="imageURL" placeholder="https://ytalebanon.org/assets/images/news/your-photo.png">
      <p class="helper-text">Link to a photo already uploaded on your site. Leave blank for a clean text-only card.</p>
    </div>

    <div class="field">
      <label class="checkbox-row"><input type="checkbox" name="sendPush" value="1"> Also send a push notification to everyone</label>
    </div>

    <button type="submit">Publish Article</button>
  </form>

  <hr class="divider">

  <h2 style="font-family:'Fraunces',serif;font-style:italic;font-size:18px;margin:0 0 16px;">Current articles (<?php echo count($displayNews); ?>)</h2>

  <?php if (empty($displayNews)): ?>
    <p class="helper-text">No articles yet.</p>
  <?php else: ?>
    <div class="results-list">
      <?php foreach ($displayNews as $article): ?>
        <div class="result-item">
          <p class="result-question" dir="rtl"><?php echo htmlspecialchars($article['title']); ?></p>
          <p class="result-meta" dir="rtl"><?php echo htmlspecialchars($article['summary']); ?></p>
          <p class="result-meta">
            <a href="<?php echo htmlspecialchars($article['url']); ?>" target="_blank" rel="noopener">Read article ↗</a>
            <?php if (!empty($article['imageURL'])): ?> · has photo<?php endif; ?>
          </p>
          <form method="post" onsubmit="return confirm('Delete this article? This cannot be undone.');" style="margin-top: 10px;">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="articleId" value="<?php echo htmlspecialchars($article['id']); ?>">
            <button type="submit" class="btn-secondary" style="width: auto; padding: 8px 16px; font-size: 12px;">Delete</button>
          </form>
        </div>
      <?php endforeach; ?>
    </div>
  <?php endif; ?>
</div>
</body>
</html>
