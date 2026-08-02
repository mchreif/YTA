<?php
/**
 * Shared OneSignal push sender, used by send-alert.php (always) and
 * manage-polls.php / manage-news.php / manage-event.php (only when their
 * optional "also send a push" checkbox is ticked).
 */

/** Sends a push via OneSignal's REST API. Requires $config['appId'] and $config['restApiKey']. */
function yta_send_push(array $config, string $title, string $message): array
{
    if (empty($config['appId']) || empty($config['restApiKey'])) {
        return [false, 'OneSignal is not configured (missing appId/restApiKey in config.local.php).'];
    }

    $payload = [
        'app_id' => $config['appId'],
        'target_channel' => 'push',
        'included_segments' => ['Subscribed Users'],
        'headings' => ['en' => $title],
        'contents' => ['en' => $message],
    ];

    $ch = curl_init('https://api.onesignal.com/notifications');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Authorization: Key ' . $config['restApiKey'],
        ],
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_TIMEOUT => 15,
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($response === false) {
        return [false, 'Push failed to send: ' . $curlError];
    }
    if ($httpCode < 200 || $httpCode >= 300) {
        return [false, 'OneSignal rejected the push (HTTP ' . $httpCode . '): ' . $response];
    }
    return [true, null];
}
