<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

$db_host = 'localhost';
$db_user = 'root';
$db_pass = '';
$db_name = 'psu-bc-almns-db';
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

if ($conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed']);
    exit;
}

$data = json_decode(file_get_contents('php://input'), true);
$student_number = $data['student_number'] ?? '';

if (empty($student_number)) {
    echo json_encode(['status' => 'error', 'message' => 'Student Number is required.']);
    exit;
}

// Find student_id and email from student_login table
$stmt = $conn->prepare("SELECT student_id, email FROM student_login WHERE student_number = ?");
$stmt->bind_param("s", $student_number);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $row = $result->fetch_assoc();
    
    // Check if email exists
    if (empty($row['email'])) {
        echo json_encode([
            'status' => 'error', 
            'message' => 'No email address is registered for this account. Please contact an administrator directly.'
        ]);
        exit;
    }

    // Success! Send back the student_id and their email
    echo json_encode([
        'status' => 'success',
        'student_id' => $row['student_id'],
        'email' => $row['email'] // Send the full email for the next step
    ]);
    
} else {
    echo json_encode(['status' => 'error', 'message' => 'Student Number not found.']);
}

$stmt->close();
$conn->close();
?>