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
$admin_notes = $data['notes'] ?? 'Insufficient information provided.';

if (empty($request_id)) {
     echo json_encode(['status' => 'error', 'message' => 'Request ID is missing.']);
     exit;
}

// Mark the request as 'denied'
$stmt = $conn->prepare(
    "UPDATE account_recovery_requests 
     SET status = 'denied', admin_notes = ?, resolved_by_admin_id = ?, resolved_date = NOW()
     WHERE request_id = ? AND status = 'pending_admin'"
);
$stmt->bind_param("sii", $admin_notes, $admin_id, $request_id);

if ($stmt->execute() && $stmt->affected_rows > 0) {
    echo json_encode(['status' => 'success', 'message' => 'Request has been denied.']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Failed to update request or request not found.']);
}
$stmt->close();
$conn->close();
?>