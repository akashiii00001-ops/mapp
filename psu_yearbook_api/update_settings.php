<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

$conn = new mysqli('localhost', 'root', '', 'psu-bc-almns-db');

$data = json_decode(file_get_contents('php://input'), true);

$student_id = $data['student_id'] ?? 0;
$type = $data['type'] ?? ''; // 'password' or 'email'
$value = $data['value'] ?? '';
$current_password = $data['current_password'] ?? '';

// 1. Verify Current Password
$stmt = $conn->prepare("SELECT password FROM student_login WHERE student_id = ?");
$stmt->bind_param("i", $student_id);
$stmt->execute();
$res = $stmt->get_result();

if ($res->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'User not found']);
    exit;
}

$row = $res->fetch_assoc();
if (!password_verify($current_password, $row['password'])) {
    echo json_encode(['status' => 'error', 'message' => 'Incorrect current password']);
    exit;
}

// 2. Update Data
if ($type === 'email') {
    if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid email format']);
        exit;
    }
    $stmt = $conn->prepare("UPDATE student_login SET email = ? WHERE student_id = ?");
    $stmt->bind_param("si", $value, $student_id);
} 
elseif ($type === 'password') {
    $hashed = password_hash($value, PASSWORD_DEFAULT);
    $stmt = $conn->prepare("UPDATE student_login SET password = ? WHERE student_id = ?");
    $stmt->bind_param("si", $hashed, $student_id);
} 
else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid request type']);
    exit;
}

if ($stmt->execute()) {
    echo json_encode(['status' => 'success', 'message' => ucfirst($type) . ' updated successfully']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Update failed: ' . $conn->error]);
}

$conn->close();
?>