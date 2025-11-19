<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");

$conn = new mysqli('localhost', 'root', '', 'psu-bc-almns-db');
$data = json_decode(file_get_contents('php://input'), true);

$student_id = $data['student_id'] ?? 0;
$current_password = $data['current_password'] ?? '';
$new_email = $data['new_email'] ?? null;
$new_password = $data['new_password'] ?? null;

if ($student_id == 0 || empty($current_password)) {
    echo json_encode(['status' => 'error', 'message' => 'Missing credentials']);
    exit;
}

// Verify Current Password
$stmt = $conn->prepare("SELECT password FROM student_login WHERE student_id = ?");
$stmt->bind_param("i", $student_id);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    if (!password_verify($current_password, $row['password'])) {
        echo json_encode(['status' => 'error', 'message' => 'Incorrect current password']);
        exit;
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'User not found']);
    exit;
}

// Update Fields
if ($new_email) {
    $update = $conn->prepare("UPDATE student_login SET email = ? WHERE student_id = ?");
    $update->bind_param("si", $new_email, $student_id);
    $update->execute();
}

if ($new_password) {
    $hashed = password_hash($new_password, PASSWORD_DEFAULT);
    $update = $conn->prepare("UPDATE student_login SET password = ? WHERE student_id = ?");
    $update->bind_param("si", $hashed, $student_id);
    $update->execute();
}

echo json_encode(['status' => 'success', 'message' => 'Account updated successfully']);
$conn->close();
?>