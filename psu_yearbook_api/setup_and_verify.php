<?php
header('Content-Type: application/json');

// Import PHPMailer
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'vendor/autoload.php'; 

// --- Database Connection ---
$db_host = 'localhost'; $db_user = 'root'; $db_pass = ''; $db_name = 'psu-bc-almns-db';
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
if ($conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed']); exit;
}

// --- FIX: Force database connection to UTC ---
$conn->query("SET time_zone = '+00:00'");

$data = json_decode(file_get_contents('php://input'), true);
$action = $data['action'] ?? '';
$student_id = $data['student_id'] ?? 0;
$email = $data['email'] ?? '';

if (empty($action) || empty($student_id)) {
    echo json_encode(['status' => 'error', 'message' => 'Missing required parameters.']); exit;
}

if ($action == 'send_otp') {
    // --- STEP 1: Send OTP to the user's chosen email ---
    if (empty($email)) {
        echo json_encode(['status' => 'error', 'message' => 'Email address is required.']); exit;
    }

    $otp = rand(100000, 999999);
    // --- FIX: Use gmdate() for UTC time ---
    $expiry_time = gmdate('Y-m-d H:i:s', strtotime('+5 minutes'));

    // Store OTP in the two_fa_code column temporarily
    $stmt = $conn->prepare("UPDATE student_login SET two_fa_code = ?, otp_expires = ? WHERE student_id = ?");
    $stmt->bind_param("ssi", $otp, $expiry_time, $student_id);
    if (!$stmt->execute()) {
        echo json_encode(['status' => 'error', 'message' => 'Failed to save OTP.']); exit;
    }
    $stmt->close();

    // Send Email
    $mail = new PHPMailer(true);
    try {
        $mail->isSMTP();
        $mail->Host       = 'smtp.gmail.com';
        $mail->SMTPAuth   = true;
        $mail->Username   = 'alumni.management.system1@gmail.com';
        $mail->Password   = 'cgra rahs cgpi zwjj';
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port       = 587;
        $mail->setFrom('no-reply@psu-yearbook.com', 'PSU Yearbook Setup');
        $mail->addAddress($email);
        $mail->isHTML(true);
        $mail->Subject = 'PSU Yearbook Email Verification';
        $mail->Body    = "Your email verification code is: <b>$otp</b><br>This code will expire in 5 minutes.";
        $mail->send();

        echo json_encode(['status' => 'success', 'message' => 'OTP sent to your email.']);
    
    } catch (Exception $e) {
        echo json_encode(['status' => 'error', 'message' => "Message could not be sent. Mailer Error: {$mail->ErrorInfo}"]);
    }

} elseif ($action == 'verify_otp') {
    // --- STEP 2: Verify OTP and finalize setup ---
    $otp_from_app = $data['otp'] ?? '';
    if (empty($otp_from_app)) {
        echo json_encode(['status' => 'error', 'message' => 'OTP is missing.']); exit;
    }

    // Check OTP. NOW() is now in UTC because of the SET time_zone query above.
    $stmt = $conn->prepare("SELECT two_fa_code FROM student_login WHERE student_id = ? AND otp_expires > NOW()");
    $stmt->bind_param("i", $student_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 1) {
        $row = $result->fetch_assoc();
        // Use trim() for safety, though likely not the main issue
        if (trim($row['two_fa_code']) == trim($otp_from_app)) {
            // --- SUCCESS! OTP is correct ---
            
            // 1. Save the email permanently (if this is the setup flow)
            if (!empty($email)) {
                $update_stmt = $conn->prepare("UPDATE student_login SET email = ? WHERE student_id = ?");
                $update_stmt->bind_param("si", $email, $student_id);
                $update_stmt->execute();
                $update_stmt->close();
            }

            // 2. Log the final setup step
            $log_action = "Mobile app 2FA successful";
            $log_stmt = $conn->prepare("INSERT INTO student_activity_log (student_id, action) VALUES (?, ?)");
            $log_stmt->bind_param("is", $student_id, $log_action);
            $log_stmt->execute();
            $log_stmt->close();
            
            // 3. Clear the OTP
            $clear_stmt = $conn->prepare("UPDATE student_login SET two_fa_code = NULL, otp_expires = NULL WHERE student_id = ?");
            $clear_stmt->bind_param("i", $student_id);
            $clear_stmt->execute();
            $clear_stmt->close();

            echo json_encode(['status' => 'success', 'message' => 'Email verified successfully!']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Invalid OTP.']);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'OTP expired or is invalid. Please try again.']);
    }
    $stmt->close();

} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid action.']);
}

$conn->close();
?>