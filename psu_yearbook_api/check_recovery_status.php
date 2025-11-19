<?php
header('Content-Type: application/json');

$db_host = 'localhost'; $db_user = 'root'; $db_pass = ''; $db_name = 'psu-bc-almns-db';
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
if ($conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed']); exit;
}

$data = json_decode(file_get_contents('php://input'), true);
$student_number = $data['student_number'] ?? '';

if (empty($student_number)) {
    echo json_encode(['status' => 'error', 'message' => 'Student number is required.']); exit;
}

// Find the student_id from student_number
$stmt = $conn->prepare("SELECT student_id FROM student_login WHERE student_number = ?");
$stmt->bind_param("s", $student_number);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $student_id = $result->fetch_assoc()['student_id'];
    $stmt->close();

    // Check for the *latest* open request for this student
    $req_stmt = $conn->prepare("SELECT request_id, status, admin_notes 
                                FROM account_recovery_requests 
                                WHERE student_id = ? 
                                  AND status IN ('pending_admin', 'approved', 'denied')
                                ORDER BY request_date DESC 
                                LIMIT 1");
    $req_stmt->bind_param("i", $student_id);
    $req_stmt->execute();
    $req_result = $req_stmt->get_result();

    if ($req_result->num_rows === 1) {
        $row = $req_result->fetch_assoc();
        echo json_encode([
            'status' => 'found',
            'request_id' => $row['request_id'],
            'request_status' => $row['status'],
            'admin_notes' => $row['admin_notes']
        ]);
    } else {
        echo json_encode(['status' => 'not_found', 'message' => 'No active recovery requests found.']);
    }
    $req_stmt->close();

} else {
    echo json_encode(['status' => 'error', 'message' => 'Student not found.']);
}

$conn->close();
?>