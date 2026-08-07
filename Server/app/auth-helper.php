<?php
/**
 * Shared login/session gate for the YTA admin tool suite. Call after
 * config.local.php has been loaded and validated. Renders admin-login.php
 * and exits if the visitor isn't authenticated yet; returns quietly once
 * they are.
 */
function yta_require_admin_auth(string $adminPassword): void
{
    // Bluehost's edge cache sits in front of this site and caches GET
    // responses (confirmed via response headers) — a first-time visitor's
    // login-page request could be served a cached copy, including
    // whatever session cookie was baked into that cached response, shared
    // across every visitor who hits the cache before it expires. These
    // headers ask it not to; session_regenerate_id() below is the real
    // fix regardless of whether the cache honors them.
    header('Cache-Control: no-store, no-cache, must-revalidate, private, max-age=0');
    header('Pragma: no-cache');
    header('Expires: 0');

    session_start();

    $authenticated = !empty($_SESSION['yta_admin_authed']);
    $loginError = null;

    if (!$authenticated && isset($_POST['password'])) {
        if (hash_equals($adminPassword, (string) $_POST['password'])) {
            // Always issue a fresh session ID on a successful login rather
            // than keep whatever ID this request arrived with — that ID
            // isn't guaranteed to be private (see cache note above).
            session_regenerate_id(true);
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
}
