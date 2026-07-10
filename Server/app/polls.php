<?php
/**
 * Returns all polls with live tallies for the YTA iOS app:
 * base counts from polls.json plus every vote recorded by vote.php.
 */
header('Content-Type: application/json; charset=utf-8');

$polls = json_decode(@file_get_contents(__DIR__ . '/polls.json'), true);
if (!is_array($polls)) {
    http_response_code(500);
    echo json_encode(['error' => 'polls.json missing or invalid']);
    exit;
}

$votes = json_decode(@file_get_contents(__DIR__ . '/votes.json'), true);
if (!is_array($votes)) { $votes = []; }

foreach ($polls as $pi => $poll) {
    $pollID = $poll['id'];
    foreach ($poll['options'] as $oi => $option) {
        $extra = isset($votes[$pollID][$option['id']]) ? $votes[$pollID][$option['id']] : 0;
        $polls[$pi]['options'][$oi]['votes'] = $option['votes'] + $extra;
    }
}

echo json_encode($polls);
