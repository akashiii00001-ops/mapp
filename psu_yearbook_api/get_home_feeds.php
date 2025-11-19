<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

$db_host = 'localhost';
$db_user = 'root';
$db_pass = '';
$db_name = 'psu-bc-almns-db';

$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

if ($conn->connect_error) {
    echo json_encode(['error' => 'Database connection failed']);
    exit;
}

// 1. Fetch Announcements
$announcements = [];
$sql = "SELECT title, message as description, created_at as date FROM announcements WHERE deactivated_at IS NULL ORDER BY created_at DESC LIMIT 10";
$result = $conn->query($sql);
while($row = $result->fetch_assoc()) {
    $announcements[] = $row;
}

// 2. Fetch Events
$events = [];
$sql = "SELECT title, description, start_datetime as date, location FROM events WHERE deactivated_at IS NULL ORDER BY start_datetime DESC LIMIT 10";
$result = $conn->query($sql);
while($row = $result->fetch_assoc()) {
    $events[] = $row;
}

// 3. Fetch Jobs
$jobs = [];
$sql = "SELECT job_title as title, description, company_name, location, created_at as date FROM job_hiring WHERE deactivated_at IS NULL ORDER BY created_at DESC LIMIT 10";
$result = $conn->query($sql);
while($row = $result->fetch_assoc()) {
    $jobs[] = $row;
}

echo json_encode([
    'announcements' => $announcements,
    'events' => $events,
    'jobs' => $jobs
]);

$conn->close();
?>