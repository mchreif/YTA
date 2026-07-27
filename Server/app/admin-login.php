<?php
/**
 * Shared login screen for the YTA admin tools. Included by any script
 * that has already checked $_SESSION['yta_admin_authed'] and found the
 * visitor isn't authenticated yet — expects $loginError to be set (or
 * null) by the including script.
 */
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>YTA Admin — Sign in</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&family=Fraunces:ital,wght@0,600;1,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="admin-style.css">
</head>
<body>
<div class="admin-card" style="max-width: 380px;">
  <div class="admin-header">
    <img src="https://ytalebanon.org/assets/images/logos/yam.png" alt="YTA">
    <div>
      <p class="admin-eyebrow">YTA Admin</p>
      <h1>Sign in</h1>
    </div>
  </div>
  <div class="gold-rule"></div>

  <?php if (!empty($loginError)): ?>
    <div class="banner banner-error"><?php echo htmlspecialchars($loginError); ?></div>
  <?php endif; ?>

  <form method="post">
    <div class="field">
      <label for="password">Password</label>
      <input type="password" id="password" name="password" autofocus required>
    </div>
    <button type="submit">Continue</button>
  </form>
</div>
</body>
</html>
