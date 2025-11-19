<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");

$conn = new mysqli('localhost', 'root', '', 'psu-bc-almns-db');
$data = json_decode(file_get_contents('php://input'), true);
$student_id = $data['student_id'] ?? 0;
$current_password = $data['current_password'] ?? '';
$new_email = $data['new_email'] ?? '';
$new_password = $data['new_password'] ?? '';

if ($student_id > 0 && !empty($current_password)) {
    $stmt = $conn->prepare("SELECT password FROM student_login WHERE student_id = ?");
    $stmt->bind_param("i", $student_id);
    $stmt->execute();
    $res = $stmt->get_result();
    
    if ($row = $res->fetch_assoc()) {
        if (password_verify($current_password, $row['password'])) {
            if (!empty($new_email)) {
                $upd = $conn->prepare("UPDATE student_login SET email = ? WHERE student_id = ?");
                $upd->bind_param("si", $new_email, $student_id);
                $upd->execute();
            }
            if (!empty($new_password)) {
                $hashed = password_hash($new_password, PASSWORD_DEFAULT);
                $upd = $conn->prepare("UPDATE student_login SET password = ? WHERE student_id = ?");
                $upd->bind_param("si", $hashed, $student_id);
                $upd->execute();
            }
            echo json_encode(['status' => 'success', 'message' => 'Settings updated successfully']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Incorrect current password']);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'User not found']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Missing fields']);
}
$conn->close();
?>