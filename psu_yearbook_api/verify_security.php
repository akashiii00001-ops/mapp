<?php
header('Content-Type: application/json');

// --- Database Connection ---
$db_host = 'localhost'; $db_user = 'root'; $db_pass = ''; $db_name = 'psu-bc-almns-db';
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
if ($conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed']); exit;
}

// --- Get Data from Flutter App ---
$data = json_decode(file_get_contents('php://input'), true);

$student_id = $data['student_id'] ?? 0;
$mother_lname_answer = $data['mother_lname'] ?? '';
$barangay_answer = $data['barangay'] ?? '';
$course_answer = $data['course'] ?? '';

if (empty($student_id)) {
    echo json_encode(['status' => 'error', 'message' => 'Student ID is missing.']); exit;
}

// --- 1. Get Correct Answers from Database ---
$stmt = $conn->prepare("
    SELECT 
        p.mother_lname, 
        a.barangay, 
        d.department_name
    FROM students s
    LEFT JOIN parents p ON s.student_id = p.student_id
    LEFT JOIN address a ON s.student_id = a.student_id
    LEFT JOIN department d ON s.department_id = d.department_id
    WHERE s.student_id = ?
");
$stmt->bind_param("i", $student_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $row = $result->fetch_assoc();
    
    // --- 2. Compare Answers (case-insensitive) ---
    $is_mother_correct = strcasecmp(trim($row['mother_lname']), trim($mother_lname_answer)) == 0;
    $is_barangay_correct = strcasecmp(trim($row['barangay']), trim($barangay_answer)) == 0;
    $is_course_correct = strcasecmp(trim($row['department_name']), trim($course_answer)) == 0;

    if ($is_mother_correct && $is_barangay_correct && $is_course_correct) {
        // --- ALL ANSWERS ARE CORRECT ---
        
        // Log this step
        $action = "Security questions passed";
        $log_stmt = $conn->prepare("INSERT INTO student_activity_log (student_id, action) VALUES (?, ?)");
        $log_stmt->bind_param("is", $student_id, $action);
        $log_stmt->execute();
        $log_stmt->close();
        
        // Send response to proceed to email *setup*
        echo json_encode([
            'status' => 'email_setup_required',
            'message' => 'Security questions correct. Please set up your email.'
        ]);

    } else {
        // --- ONE OR MORE ANSWERS ARE WRONG ---
        echo json_encode(['status' => 'error', 'message' => 'One or more answers are incorrect. Please try again.']);
    }

} else {
    echo json_encode(['status' => 'error', 'message' => 'Could not find student data.']);
}

$stmt->close();
$conn->close();
?>