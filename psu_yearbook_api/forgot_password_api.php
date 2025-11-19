<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'vendor/autoload.php'; 

$db_host = 'localhost'; 
$db_user = 'root'; 
$db_pass = ''; 
$db_name = 'psu-bc-almns-db';
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
if ($conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed']); exit;
}

// Force database connection to UTC
$conn->query("SET time_zone = '+00:00'");

// 1. Try to get JSON input first
$data = json_decode(file_get_contents('php://input'), true);

// 2. If JSON is null, it might be a Multipart Form POST (file upload)
if (!$data && !empty($_POST)) {
    $data = $_POST;
}

$action = $data['action'] ?? '';

switch ($action) {
    case 'check_account':
        $student_number = $data['student_number'] ?? '';
        $stmt = $conn->prepare("SELECT student_id, email FROM student_login WHERE student_number = ?");
        $stmt->bind_param("s", $student_number);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 1) {
            $row = $result->fetch_assoc();
            if (empty($row['email'])) {
                echo json_encode(['status' => 'no_email', 'student_id' => $row['student_id'], 'message' => 'No email on file. Please request a manual reset.']);
            } else {
                echo json_encode(['status' => 'email_found', 'student_id' => $row['student_id'], 'email' => $row['email']]);
            }
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Student number not found.']);
        }
        $stmt->close();
        break;

    case 'send_recovery_otp':
        $student_id = $data['student_id'] ?? 0;
        $email = $data['email'] ?? '';
        
        $otp = rand(100000, 999999);
        $expiry_time = gmdate('Y-m-d H:i:s', strtotime('+5 minutes'));

        $stmt = $conn->prepare("UPDATE student_login SET two_fa_code = ?, otp_expires = ? WHERE student_id = ?");
        $stmt->bind_param("ssi", $otp, $expiry_time, $student_id);
        $stmt->execute();
        $stmt->close();

        $mail = new PHPMailer(true);
        try {
            $mail->isSMTP();
            $mail->Host       = 'smtp.gmail.com';
            $mail->SMTPAuth   = true;
            $mail->Username   = 'alumni.management.system1@gmail.com';
            $mail->Password   = 'cgra rahs cgpi zwjj';
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            $mail->Port       = 587;
            $mail->setFrom('no-reply@psu-yearbook.com', 'PSU Yearbook Admin');
            $mail->addAddress($email);
            $mail->isHTML(true);
            $mail->Subject = 'PSU Yearbook Account Recovery Code';
            $mail->Body    = "Your account recovery OTP is: <b>$otp</b><br>This code will expire in 5 minutes.";
            $mail->send();
            echo json_encode(['status' => 'otp_sent', 'message' => 'OTP sent to your email.']);
        } catch (Exception $e) {
            echo json_encode(['status' => 'error', 'message' => "Message could not be sent. Mailer Error: {$mail->ErrorInfo}"]);
        }
        break;

    case 'verify_recovery_otp':
        $student_id = $data['student_id'] ?? 0;
        $otp_from_app = $data['otp'] ?? '';
        
        $stmt = $conn->prepare("SELECT two_fa_code FROM student_login WHERE student_id = ? AND two_fa_code = ? AND otp_expires > NOW()");
        $stmt->bind_param("is", $student_id, $otp_from_app);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 1) {
            echo json_encode(['status' => 'success', 'message' => 'OTP verified.']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Invalid or expired OTP.']);
        }
        $stmt->close();
        break;

    case 'reset_password':
        $student_id = $data['student_id'] ?? 0;
        $new_password = $data['password'] ?? '';
        
        $hashed_password = password_hash($new_password, PASSWORD_DEFAULT);
        
        $stmt = $conn->prepare("UPDATE student_login SET password = ?, two_fa_code = NULL, otp_expires = NULL WHERE student_id = ?");
        $stmt->bind_param("si", $hashed_password, $student_id);
        
        if ($stmt->execute()) {
            echo json_encode(['status' => 'success', 'message' => 'Password reset successfully.']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Failed to update password.']);
        }
        $stmt->close();
        break;

    case 'submit_manual_request':
        $student_id = $data['student_id'] ?? 0;
        $message = $data['message'] ?? '';

        // --- FILE UPLOAD HANDLING ---
        $upload_dir = 'uploads/recovery_proofs/';
        if (!file_exists($upload_dir)) {
            mkdir($upload_dir, 0777, true);
        }

        $id_proof_path = '';
        $selfie_proof_path = '';

        // 1. Handle ID Proof
        if (isset($_FILES['id_proof']) && $_FILES['id_proof']['error'] === UPLOAD_ERR_OK) {
            $ext = pathinfo($_FILES['id_proof']['name'], PATHINFO_EXTENSION);
            $new_name = 'id_' . $student_id . '_' . uniqid() . '.' . $ext;
            if (move_uploaded_file($_FILES['id_proof']['tmp_name'], $upload_dir . $new_name)) {
                $id_proof_path = $upload_dir . $new_name;
            }
        }

        // 2. Handle Selfie Proof
        if (isset($_FILES['selfie_proof']) && $_FILES['selfie_proof']['error'] === UPLOAD_ERR_OK) {
            $ext = pathinfo($_FILES['selfie_proof']['name'], PATHINFO_EXTENSION);
            $new_name = 'selfie_' . $student_id . '_' . uniqid() . '.' . $ext;
            if (move_uploaded_file($_FILES['selfie_proof']['tmp_name'], $upload_dir . $new_name)) {
                $selfie_proof_path = $upload_dir . $new_name;
            }
        }

        // Close any existing requests
        $close_stmt = $conn->prepare("UPDATE account_recovery_requests SET status = 'closed' WHERE student_id = ? AND status IN ('approved', 'denied')");
        $close_stmt->bind_param("i", $student_id);
        $close_stmt->execute();
        $close_stmt->close();

        // Create new request with file paths
        $stmt = $conn->prepare("INSERT INTO account_recovery_requests (student_id, message, id_proof_path, selfie_proof_path, status) VALUES (?, ?, ?, ?, 'pending_admin')");
        $stmt->bind_param("isss", $student_id, $message, $id_proof_path, $selfie_proof_path);
        
        if ($stmt->execute()) {
            $request_id = $conn->insert_id;
            echo json_encode(['status' => 'success', 'message' => 'Request submitted.', 'reference_id' => $request_id]);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Failed to submit request.']);
        }
        $stmt->close();
        break;

    default:
        echo json_encode(['status' => 'error', 'message' => 'Invalid action.']);
}

$conn->close();
?>