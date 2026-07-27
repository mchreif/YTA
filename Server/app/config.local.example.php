<?php
/**
 * Copy this file to config.local.php (same folder) and fill in real
 * values. config.local.php is intentionally excluded from git — it holds
 * real secrets and must never be committed or shared.
 */
return [
    // OneSignal dashboard → Settings → Keys & IDs → "OneSignal App ID".
    'appId' => 'REPLACE_WITH_ONESIGNAL_APP_ID',

    // OneSignal dashboard → Settings → Keys & IDs → REST API Keys →
    // Add Key (scope: Notifications - Create only). Treat like a password.
    'restApiKey' => 'REPLACE_WITH_ONESIGNAL_REST_API_KEY',

    // A password of your choosing to protect send-alert.php from
    // strangers who might guess the URL. Pick something only YTA staff know.
    'adminPassword' => 'REPLACE_WITH_A_PASSWORD_YOU_CHOOSE',
];
