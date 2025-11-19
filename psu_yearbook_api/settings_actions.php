<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'vendor/autoload.php'; 

$conn = new mysqli('localhost', 'root', '', 'psu-bc-almns-db');

$data = json_decode(file_get_contents('php://input'), true);
$action = $data['action'] ?? '';
$student_id = $data['student_id'] ?? 0;

if ($student_id == 0) {
    echo json_encode(['status' => 'error', 'message' => 'Invalid Session']);
    exit();
}

// Helper to log activity
function logActivity($conn, $student_id, $action_text) {
    $stmt = $conn->prepare("INSERT INTO student_activity_log (student_id, action) VALUES (?, ?)");
    $stmt->bind_param("is", $student_id, $action_text);
    $stmt->execute();
}

function sendEmail($email, $subject, $body) {
    $mail = new PHPMailer(true);
    try {
        // !!! REPLACE WITH YOUR ACTUAL SMTP CREDENTIALS !!!
        $mail->isSMTP();
        $mail->Host       = 'smtp.gmail.com';
        $mail->SMTPAuth   = true;
         $mail->Username   = 'alumni.management.system1@gmail.com';
            $mail->Password   = 'cgra rahs cgpi zwjj'; 
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            $mail->Port       = 587;

        $mail->setFrom('admin@psu.edu.ph', 'PSU Yearbook Security');
        $mail->addAddress($email);
        $mail->isHTML(true);
        $mail->Subject = $subject;
        $mail->Body    = $body;

        $mail->send();
        return true;
    } catch (Exception $e) {
        return false;
    }
}

if ($action === 'send_otp_current') {
    $stmt = $conn->prepare("SELECT email FROM student_login WHERE student_id = ?");
    $stmt->bind_param("i", $student_id);
    $stmt->execute();
    $res = $stmt->get_result()->fetch_assoc();
    
    if ($res && !empty($res['email'])) {
        $otp = rand(100000, 999999);
        $expiry = date("Y-m-d H:i:s", strtotime("+10 minutes"));
        
        $update = $conn->prepare("UPDATE student_login SET two_fa_code = ?, otp_expires = ? WHERE student_id = ?");
        $update->bind_param("ssi", $otp, $expiry, $student_id);
        $update->execute();
        
        if (sendEmail($res['email'], "Security OTP", "Your OTP is: <b>$otp</b>")) {
            echo json_encode(['status' => 'success', 'message' => 'OTP sent to ' . $res['email']]);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Failed to send email']);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'No email linked']);
    }

} elseif ($action === 'verify_otp') {
    $code = $data['code'] ?? '';
    $stmt = $conn->prepare("SELECT two_fa_code, otp_expires FROM student_login WHERE student_id = ?");
    $stmt->bind_param("i", $student_id);
    $stmt->execute();
    $res = $stmt->get_result()->fetch_assoc();
    
    if ($res['two_fa_code'] == $code && strtotime($res['otp_expires']) > time()) {
        echo json_encode(['status' => 'success', 'message' => 'Verified']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Invalid or Expired Code']);
    }

} elseif ($action === 'update_email') {
    // Verify code one last time before update
    $code = $data['code'];
    $new_email = $data['new_email'];
    
    $stmt = $conn->prepare("SELECT two_fa_code FROM student_login WHERE student_id = ?");
    $stmt->bind_param("i", $student_id);
    $stmt->execute();
    $res = $stmt->get_result()->fetch_assoc();
    
    if ($res['two_fa_code'] == $code) {
        $upd = $conn->prepare("UPDATE student_login SET email = ?, two_fa_code = NULL WHERE student_id = ?");
        $upd->bind_param("si", $new_email, $student_id);
        
        if($upd->execute()) {
            logActivity($conn, $student_id, "Updated email address");
            echo json_encode(['status' => 'success', 'message' => 'Email updated!']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Email update failed']);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Invalid code']);
    }

} elseif ($action === 'change_password') {
    $old_pass = $data['old_password'];
    $new_pass = password_hash($data['new_password'], PASSWORD_DEFAULT);
    
    $stmt = $conn->prepare("SELECT password FROM student_login WHERE student_id = ?");
    $stmt->bind_param("i", $student_id);
    $stmt->execute();
    $res = $stmt->get_result()->fetch_assoc();
    
    if (password_verify($old_pass, $res['password'])) {
        $upd = $conn->prepare("UPDATE student_login SET password = ? WHERE student_id = ?");
        $upd->bind_param("si", $new_pass, $student_id);
        $upd->execute();
        logActivity($conn, $student_id, "Changed password via Settings");
        echo json_encode(['status' => 'success', 'message' => 'Password changed successfully']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Incorrect old password']);
    }

} elseif ($action === 'forgot_password') {
    // Sends a reset email
    $stmt = $conn->prepare("SELECT email FROM student_login WHERE student_id = ?");
    $stmt->bind_param("i", $student_id);
    $stmt->execute();
    $res = $stmt->get_result()->fetch_assoc();
    
    if ($res && !empty($res['email'])) {
        // In a real app, generate a token. Here we send instructions.
        $body = "A password reset was requested for your account. Please contact admin or use the recovery page.";
        if (sendEmail($res['email'], "Password Reset Request", $body)) {
            logActivity($conn, $student_id, "Requested Password Reset via Settings");
            echo json_encode(['status' => 'success', 'message' => 'Reset instructions sent to your email']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Could not send email']);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'No email linked']);
    }
}

$conn->close();
?>