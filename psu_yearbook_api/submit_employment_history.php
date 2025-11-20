<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");

$conn = new mysqli('localhost', 'root', '', 'psu-bc-almns-db');

if ($conn->connect_error) {
    die(json_encode(['status' => 'error', 'message' => 'Database connection failed']));
}

$data = json_decode(file_get_contents('php://input'), true);

$student_id = $data['student_id'] ?? 0;
$status = $data['status'] ?? 'Not Specified';

// Fix: Map Flutter "Rather Not Say" to DB ENUM "Not Specified"
if ($status === 'Rather Not Say') $status = 'Not Specified';

// Logic: If not Employed, force everything else to NULL or Not Applicable
if ($status !== 'Employed') {
    $job_title = NULL;
    $company = NULL;
    $industry_id = NULL;
    $time_first_job = 'Not Applicable'; // DB ENUM default
    $relevant = NULL;
    $location = NULL;
} else {
    $job_title = $data['job_title'] ?? '';
    $company = $data['company'] ?? '';
    $industry_id = !empty($data['industry_id']) ? $data['industry_id'] : NULL;
    $time_first_job = $data['time_to_first_job'] ?? 'Not Applicable';
    $relevant = $data['relevance'] ?? 'No';
    $location = $data['location'] ?? '';
}

if ($student_id > 0) {
    // 1. Check if a record already exists for this student
    $check_stmt = $conn->prepare("SELECT history_id FROM alumni_employment_history WHERE student_id = ?");
    $check_stmt->bind_param("i", $student_id);
    $check_stmt->execute();
    $result = $check_stmt->get_result();
    $exists = $result->num_rows > 0;
    $check_stmt->close();

    if ($exists) {
        // 2. Record exists: UPDATE it
        // Note: We update date_recorded to the current time as well
        $stmt = $conn->prepare("UPDATE alumni_employment_history 
                                SET employment_status = ?, 
                                    job_title = ?, 
                                    company_name = ?, 
                                    industry_id = ?, 
                                    time_to_first_job = ?, 
                                    is_relevant_to_course = ?, 
                                    location_city = ?, 
                                    date_recorded = CURRENT_TIMESTAMP 
                                WHERE student_id = ?");
        // Types: s=string, i=int. 
        // Params order: status, job, company, industry, time, relevant, location, student_id
        $stmt->bind_param("sssisssi", $status, $job_title, $company, $industry_id, $time_first_job, $relevant, $location, $student_id);
        $action_msg = 'History updated successfully';
    } else {
        // 3. No record: INSERT a new one
        $stmt = $conn->prepare("INSERT INTO alumni_employment_history (student_id, employment_status, job_title, company_name, industry_id, time_to_first_job, is_relevant_to_course, location_city) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        // Params order: student_id, status, job, company, industry, time, relevant, location
        $stmt->bind_param("isssisss", $student_id, $status, $job_title, $company, $industry_id, $time_first_job, $relevant, $location);
        $action_msg = 'History saved successfully';
    }

    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => $action_msg]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Database error: ' . $stmt->error]);
    }
    $stmt->close();
} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid Student ID']);
}
$conn->close();
?>