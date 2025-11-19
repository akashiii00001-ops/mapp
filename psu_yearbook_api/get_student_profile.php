<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");

$conn = new mysqli('localhost', 'root', '', 'psu-bc-almns-db');
$data = json_decode(file_get_contents('php://input'), true);
$student_id = $data['student_id'] ?? 0;

if ($student_id > 0) {
    $sql = "SELECT s.fname, s.lname, s.profile_photo, b.batch_year, l.email 
            FROM students s 
            JOIN batch b ON s.batch_id = b.batch_id 
            LEFT JOIN student_login l ON s.student_id = l.student_id 
            WHERE s.student_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $student_id);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($row = $result->fetch_assoc()) {
        echo json_encode(['status' => 'success', 'data' => $row]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Student not found']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid ID']);
}
$conn->close();
?>