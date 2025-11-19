<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

$conn = new mysqli('localhost', 'root', '', 'psu-bc-almns-db');

$data = json_decode(file_get_contents('php://input'), true);

$student_id = $data['student_id'] ?? 0;
$status = $data['status'] ?? 'Not Specified';
$job_title = $data['job_title'] ?? '';
$company = $data['company'] ?? '';
$industry_id = $data['industry_id'] ?? NULL;
$time_first_job = $data['time_to_first_job'] ?? 'Not Applicable';
$relevant = $data['relevance'] ?? 'No';

if ($student_id > 0) {
    $stmt = $conn->prepare("INSERT INTO alumni_employment_history (student_id, employment_status, job_title, company_name, industry_id, time_to_first_job, is_relevant_to_course) VALUES (?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("isssiss", $student_id, $status, $job_title, $company, $industry_id, $time_first_job, $relevant);

    if ($stmt->execute()) {
        echo json_encode(['status' => 'success']);
    } else {
        echo json_encode(['status' => 'error', 'message' => $stmt->error]);
    }
    $stmt->close();
} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid Data']);
}
$conn->close();
?>