<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

$conn = new mysqli('localhost', 'root', '', 'psu-bc-almns-db');

$student_id = isset($_GET['student_id']) ? intval($_GET['student_id']) : 0;

if ($student_id > 0) {
    $stmt = $conn->prepare("SELECT history_id FROM alumni_employment_history WHERE student_id = ? LIMIT 1");
    $stmt->bind_param("i", $student_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        echo json_encode(['status' => 'found']);
    } else {
        echo json_encode(['status' => 'not_found']);
    }
    $stmt->close();
} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid ID']);
}
$conn->close();
?>