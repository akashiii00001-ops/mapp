<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

$conn = new mysqli('localhost', 'root', '', 'psu-bc-almns-db');

$response = ['announcements' => [], 'events' => [], 'jobs' => []];

// 1. Fetch Announcements
$sql = "SELECT a.announcement_id, a.title, a.message, 
        (SELECT photo_path FROM announcement_photos ap WHERE ap.announcement_id = a.announcement_id LIMIT 1) as photo_path 
        FROM announcements a WHERE a.deactivated_at IS NULL ORDER BY a.created_at DESC";
$result = $conn->query($sql);
while($row = $result->fetch_assoc()) {
    $response['announcements'][] = $row;
}

// 2. Fetch Events
$sql = "SELECT e.event_id, e.title, e.description, 
        (SELECT photo_path FROM event_photos ep WHERE ep.event_id = e.event_id LIMIT 1) as photo_path 
        FROM events e WHERE e.deactivated_at IS NULL ORDER BY e.created_at DESC";
$result = $conn->query($sql);
while($row = $result->fetch_assoc()) {
    $response['events'][] = $row;
}

// 3. Fetch Jobs
$sql = "SELECT j.job_id, j.job_title, j.company_name, 
        (SELECT photo_path FROM job_hiring_photos jp WHERE jp.job_id = j.job_id LIMIT 1) as photo_path 
        FROM job_hiring j WHERE j.deactivated_at IS NULL ORDER BY j.created_at DESC";
$result = $conn->query($sql);
while($row = $result->fetch_assoc()) {
    $response['jobs'][] = $row;
}

echo json_encode($response);
$conn->close();
?>