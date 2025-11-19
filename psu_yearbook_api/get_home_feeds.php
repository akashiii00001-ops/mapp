<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

// Database Connection
$conn = new mysqli('localhost', 'root', '', 'psu-bc-almns-db');
$conn->query("SET time_zone = '+00:00'");

if ($conn->connect_error) {
    echo json_encode(['error' => 'Database connection failed']);
    exit;
}

$student_id = isset($_GET['student_id']) ? intval($_GET['student_id']) : 0;

// 1. Fetch Announcements
$announcements = [];
$sql = "SELECT title, message as description, created_at as date FROM announcements WHERE deactivated_at IS NULL ORDER BY created_at DESC LIMIT 10";
$result = $conn->query($sql);
while($row = $result->fetch_assoc()) { $announcements[] = $row; }

// 2. Fetch Events
$events = [];
$sql = "SELECT title, description, start_datetime as date, location FROM events WHERE deactivated_at IS NULL ORDER BY start_datetime DESC LIMIT 10";
$result = $conn->query($sql);
while($row = $result->fetch_assoc()) { $events[] = $row; }

// 3. Fetch Jobs
$jobs = [];
$sql = "SELECT job_title as title, description, company_name, location, created_at as date FROM job_hiring WHERE deactivated_at IS NULL ORDER BY created_at DESC LIMIT 10";
$result = $conn->query($sql);
while($row = $result->fetch_assoc()) { $jobs[] = $row; }

// 4. Check for Notifications (New items since last check in student_login)
$has_notification = false;
if ($student_id > 0) {
    // Get user's last check time from student_login
    $check_sql = "SELECT last_notification_check FROM student_login WHERE student_id = $student_id";
    $check_res = $conn->query($check_sql);
    $last_check = ($check_res->num_rows > 0) ? $check_res->fetch_assoc()['last_notification_check'] : '2000-01-01 00:00:00';

    // Check if anything new exists
    $notify_sql = "
        SELECT 1 FROM announcements WHERE created_at > '$last_check' AND deactivated_at IS NULL
        UNION
        SELECT 1 FROM events WHERE created_at > '$last_check' AND deactivated_at IS NULL
        UNION
        SELECT 1 FROM job_hiring WHERE created_at > '$last_check' AND deactivated_at IS NULL
        LIMIT 1
    ";
    
    if ($conn->query($notify_sql)->num_rows > 0) {
        $has_notification = true;
    }
    
    // Update the last check time to NOW so they don't see the badge again immediately
    $conn->query("UPDATE student_login SET last_notification_check = CURRENT_TIMESTAMP WHERE student_id = $student_id");
}

echo json_encode([
    'announcements' => $announcements,
    'events' => $events,
    'jobs' => $jobs,
    'has_notification' => $has_notification
]);

$conn->close();
?>