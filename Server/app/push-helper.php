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
        // OneSignal's newer "Subscriptions" model (apps created after their
        // migration off the old "Players" model) doesn't have a segment
        // literally named "Subscribed Users" — that was the legacy default.
        // "Total Subscriptions" is the current everyone-segment name.
        'included_segments' => ['Total Subscriptions'],
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

    // OneSignal can return HTTP 200 even when nobody was actually notified —
    // e.g. an empty `id` with an `errors` array when the target segment
    // matched zero real subscribers. Treat that as a failure too, instead of
    // reporting success on a push that reached no one.
    $decoded = json_decode($response, true);
    if (is_array($decoded) && empty($decoded['id']) && !empty($decoded['errors'])) {
        $errors = is_array($decoded['errors']) ? implode('; ', $decoded['errors']) : $decoded['errors'];
        return [false, 'OneSignal accepted the request but sent to nobody: ' . $errors];
    }

    return [true, null];
}
