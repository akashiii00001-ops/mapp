<?php
header('Content-Type: application/json');

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'vendor/autoload.php'; 

$db_host = 'localhost'; $db_user = 'root'; $db_pass = ''; $db_name = 'psu-bc-almns-db';
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

if ($conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed']); exit;
}
$conn->query("SET time_zone = '+00:00'");

$data = json_decode(file_get_contents('php://input'), true);
$action = $data['action'] ?? '';
$student_id = $data['student_id'] ?? 0;
$email = $data['email'] ?? '';

// --- HELPER: LOG ACTIVITY ---
function logActivity($conn, $student_id, $action) {
    $stmt = $conn->prepare("INSERT INTO student_activity_log (student_id, action) VALUES (?, ?)");
    $stmt->bind_param("is", $student_id, $action);
    $stmt->execute();
    $stmt->close();
}

if ($action == 'send_otp') {
    if (empty($email)) {
        echo json_encode(['status' => 'error', 'message' => 'Email address is required.']); exit;
    }

    $otp = rand(100000, 999999);
    $expiry_time = gmdate('Y-m-d H:i:s', strtotime('+5 minutes'));

    $stmt = $conn->prepare("UPDATE student_login SET two_fa_code = ?, otp_expires = ? WHERE student_id = ?");
    $stmt->bind_param("ssi", $otp, $expiry_time, $student_id);
    
    if ($stmt->execute()) {
        $mail = new PHPMailer(true);
        try {
            $mail->isSMTP();
            $mail->Host       = 'smtp.gmail.com';
            $mail->SMTPAuth   = true;
            $mail->Username   = 'alumni.management.system1@gmail.com';
            $mail->Password   = 'cgra rahs cgpi zwjj'; 
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            $mail->Port       = 587;

            // --- FIX FOR LOCALHOST / XAMPP SSL ISSUES ---
            $mail->SMTPOptions = array(
                'ssl' => array(
                    'verify_peer' => false,
                    'verify_peer_name' => false,
                    'allow_self_signed' => true
                )
            );

            $mail->setFrom('no-reply@psu-yearbook.com', 'PSU Yearbook Setup');
            $mail->addAddress($email);
            $mail->isHTML(true);
            $mail->Subject = 'PSU Yearbook Email Verification';
            $mail->Body    = "Your email verification code is: <b>$otp</b><br>This code will expire in 5 minutes.";
            
            $mail->send();

            // Log the attempt
            logActivity($conn, $student_id, "Requested OTP for Email Setup");

            echo json_encode(['status' => 'success', 'message' => 'OTP sent to your email.']);
        
        } catch (Exception $e) {
            echo json_encode(['status' => 'error', 'message' => "Mailer Error: {$mail->ErrorInfo}"]);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to save OTP.']);
    }
    $stmt->close();

} elseif ($action == 'verify_otp') {
    $otp_from_app = $data['otp'] ?? '';
    
    $stmt = $conn->prepare("SELECT two_fa_code FROM student_login WHERE student_id = ? AND otp_expires > NOW()");
    $stmt->bind_param("i", $student_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 1) {
        $row = $result->fetch_assoc();
        if (trim($row['two_fa_code']) == trim($otp_from_app)) {
            
            if (!empty($email)) {
                $update_stmt = $conn->prepare("UPDATE student_login SET email = ? WHERE student_id = ?");
                $update_stmt->bind_param("si", $email, $student_id);
                $update_stmt->execute();
                $update_stmt->close();
            }

            // Log Success
            logActivity($conn, $student_id, "Verified Email/OTP Successfully");
            
            $clear_stmt = $conn->prepare("UPDATE student_login SET two_fa_code = NULL, otp_expires = NULL WHERE student_id = ?");
            $clear_stmt->bind_param("i", $student_id);
            $clear_stmt->execute();
            $clear_stmt->close();

            echo json_encode(['status' => 'success', 'message' => 'Email verified successfully!']);
        } else {
            // Log Failure
            logActivity($conn, $student_id, "Failed OTP Verification Attempt");
            echo json_encode(['status' => 'error', 'message' => 'Invalid OTP.']);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'OTP expired or invalid.']);
    }
    $stmt->close();

} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid action.']);
}

$conn->close();
?>