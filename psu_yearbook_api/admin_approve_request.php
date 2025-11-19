<?php
header('Content-Type: application/json');
// --- ADD YOUR ADMIN SESSION/AUTHENTICATION CHECK HERE ---
// if (!isAdmin()) { echo json_encode(['status' => 'error', 'message' => 'Unauthorized']); exit; }

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
$request_id = $data['request_id'] ?? 0;
$admin_id = 1; // Get this from your admin session
$admin_notes = $data['notes'] ?? 'Approved. Password has been reset to your Student Number.';

if (empty($request_id)) {
     echo json_encode(['status' => 'error', 'message' => 'Request ID is missing.']);
     exit;
}

// 1. Get student_id and student_number for this request
$stmt = $conn->prepare(
    "SELECT r.student_id, sl.student_number FROM account_recovery_requests r
     JOIN student_login sl ON r.student_id = sl.student_id
     WHERE r.request_id = ? AND r.status = 'pending_admin'"
);
$stmt->bind_param("i", $request_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $row = $result->fetch_assoc();
    $student_id = $row['student_id'];
    $student_number = $row['student_number']; // This will be the new password

    // 2. Reset the password (hash the student_number)
    // This matches your existing security (password_hash)
    $new_password_hash = password_hash($student_number, PASSWORD_DEFAULT);
    
    $update_pass_stmt = $conn->prepare("UPDATE student_login SET password = ? WHERE student_id = ?");
    $update_pass_stmt->bind_param("si", $new_password_hash, $student_id);
    $update_pass_stmt->execute();
    $update_pass_stmt->close();

    // 3. Mark the request as 'approved'
    $update_req_stmt = $conn->prepare(
        "UPDATE account_recovery_requests 
         SET status = 'approved', admin_notes = ?, resolved_by_admin_id = ?, resolved_date = NOW()
         WHERE request_id = ?"
    );
    $update_req_stmt->bind_param("sii", $admin_notes, $admin_id, $request_id);
    $update_req_stmt->execute();
    $update_req_stmt->close();
    
    echo json_encode(['status' => 'success', 'message' => 'Account password reset successfully.']);

} else {
    echo json_encode(['status' => 'error', 'message' => 'Request ID not found or already resolved.']);
}
$stmt->close();
$conn->close();
?>