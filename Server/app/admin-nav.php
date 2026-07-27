<?php
/**
 * Shared top nav for the admin tool suite. Expects $currentPage to be
 * set (one of 'alerts', 'polls', 'news', 'event') before including.
 */
$yta_nav_items = [
    'alerts' => ['send-alert.php', 'Alerts'],
    'polls' => ['manage-polls.php', 'Polls'],
    'news' => ['manage-news.php', 'News'],
    'event' => ['manage-event.php', 'Event'],
];
?>
<div class="admin-nav">
  <?php foreach ($yta_nav_items as $key => [$href, $label]): ?>
    <a href="<?php echo $href; ?>" class="<?php echo ($currentPage ?? '') === $key ? 'active' : ''; ?>"><?php echo $label; ?></a>
  <?php endforeach; ?>
</div>
