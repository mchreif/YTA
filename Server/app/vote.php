<?php
/**
 * Records one poll vote from the YTA iOS app.
 *
 * POST fields: poll=<pollID>, option=<optionID>
 * Response:    the updated poll as JSON (base counts from polls.json
 *              plus all votes recorded in votes.json).
 */
header('Content-Type: application/json; charset=utf-8');

$pollID   = isset($_POST['poll'])   ? trim($_POST['poll'])   : '';
$optionID = isset($_POST['option']) ? trim($_POST['option']) : '';

$pollsFile = __DIR__ . '/polls.json';
$votesFile = __DIR__ . '/votes.json';

$polls = json_decode(@file_get_contents($pollsFile), true);
if (!is_array($polls)) {
    http_response_code(500);
    echo json_encode(['error' => 'polls.json missing or invalid']);
    exit;
}

$poll = null;
foreach ($polls as $p) {
    if ($p['id'] === $pollID) { $poll = $p; break; }
}
$optionValid = false;
if ($poll !== null) {
    foreach ($poll['options'] as $o) {
        if ($o['id'] === $optionID) { $optionValid = true; break; }
    }
}
if ($poll === null || !$optionValid) {
    http_response_code(400);
    echo json_encode(['error' => 'unknown poll or option']);
    exit;
}

$handle = fopen($votesFile, 'c+');
if ($handle === false) {
    http_response_code(500);
    echo json_encode(['error' => 'cannot open votes store']);
    exit;
}
flock($handle, LOCK_EX);
$raw = stream_get_contents($handle);
$votes = json_decode($raw, true);
if (!is_array($votes)) { $votes = []; }

if (!isset($votes[$pollID])) { $votes[$pollID] = []; }
if (!isset($votes[$pollID][$optionID])) { $votes[$pollID][$optionID] = 0; }
$votes[$pollID][$optionID] += 1;

ftruncate($handle, 0);
rewind($handle);
fwrite($handle, json_encode($votes, JSON_PRETTY_PRINT));
fflush($handle);
flock($handle, LOCK_UN);
fclose($handle);

foreach ($poll['options'] as $i => $o) {
    $extra = isset($votes[$pollID][$o['id']]) ? $votes[$pollID][$o['id']] : 0;
    $poll['options'][$i]['votes'] = $o['votes'] + $extra;
}

echo json_encode($poll);
