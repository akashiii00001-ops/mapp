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

// --- Get Data from Flutter App ---
$data = json_decode(file_get_contents('php://input'), true);
$student_number = $data['student_number'] ?? '';
$password_from_app = $data['password'] ?? '';

if (empty($student_number) || empty($password_from_app)) {
    echo json_encode(['status' => 'error', 'message' => 'Student number or password is empty']); exit;
}

// --- 1. Verify Student Credentials ---
$stmt = $conn->prepare("SELECT student_id, password, email FROM student_login WHERE student_number = ?");
$stmt->bind_param("s", $student_number);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $row = $result->fetch_assoc();
    $hashed_password_from_db = $row['password'];
    $student_id = $row['student_id'];
    $email = $row['email'];

    if (password_verify($password_from_app, $hashed_password_from_db)) {
        
        // --- 2. Check if user has *ever* completed the first-time setup ---
        $log_action = "Mobile app 2FA successful"; 
        $log_check_stmt = $conn->prepare("SELECT 1 FROM student_activity_log WHERE student_id = ? AND action = ? LIMIT 1");
        $log_check_stmt->bind_param("is", $student_id, $log_action);
        $log_check_stmt->execute();
        $is_setup_complete = $log_check_stmt->get_result()->num_rows > 0;
        $log_check_stmt->close();

        if ($is_setup_complete) {
            // --- USER IS A RETURNING, VERIFIED USER ---
            if (empty($email)) {
                // Failsafe
                $action = "Login step 1 success (pending security questions)";
                $log_stmt = $conn->prepare("INSERT INTO student_activity_log (student_id, action) VALUES (?, ?)");
                $log_stmt->bind_param("is", $student_id, $action);
                $log_stmt->execute(); $log_stmt->close();
                
                echo json_encode([
                    'status' => 'security_questions_required',
                    'message' => 'Please re-verify your identity.',
                    'student_id' => $student_id
                ]);
                exit;
            }

            // Generate, Save, and Email 2FA Code
            $two_fa_code = rand(100000, 999999);
            // --- FIX: Use gmdate() for UTC time ---
            $expiry_time = gmdate('Y-m-d H:i:s', strtotime('+5 minutes'));
            
            $code_stmt = $conn->prepare("UPDATE student_login SET two_fa_code = ?, otp_expires = ? WHERE student_id = ?");
            $code_stmt->bind_param("ssi", $two_fa_code, $expiry_time, $student_id);
            $code_stmt->execute();
            $code_stmt->close();

            // Log this attempt
            $action = "Logged in via mobile app (pending 2FA)";
            $log_stmt = $conn->prepare("INSERT INTO student_activity_log (student_id, action) VALUES (?, ?)");
            $log_stmt->bind_param("is", $student_id, $action);
            $log_stmt->execute();
            $log_stmt->close();

            // --- Send Email ---
            $mail = new PHPMailer(true);
            try {
                $mail->isSMTP();
                $mail->Host       = 'smtp.gmail.com';
                $mail->SMTPAuth   = true;
                $mail->Username   = 'alumni.management.system1@gmail.com'; 
                $mail->Password   = 'cgra rahs cgpi zwjj'; 
                $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
                $mail->Port       = 587;
                $mail->setFrom('no-reply@psu-yearbook.com', 'PSU Yearbook Security');
                $mail->addAddress($email);
                $mail->isHTML(true);
                $mail->Subject = 'PSU Yearbook Login Verification Code';
                $mail->Body    = "Your login verification code is: <b>$two_fa_code</b><br>This code will expire in 5 minutes.";
                $mail->send();

                echo json_encode([
                    'status' => 'email_2fa_required', 
                    'message' => 'Please check your email for a verification code.',
                    'student_id' => $student_id,
                    'student_email' => $email 
                ]);

            } catch (Exception $e) {
                echo json_encode(['status' => 'error', 'message' => "Login success, but failed to send 2FA email. {$mail->ErrorInfo}"]);
            }

        } else {
            // --- FIRST TIME LOGIN: IDENTITY VERIFICATION NEEDED ---
            $action = "Login step 1 success (pending security questions)";
            $log_stmt = $conn->prepare("INSERT INTO student_activity_log (student_id, action) VALUES (?, ?)");
            $log_stmt->bind_param("is", $student_id, $action);
            $log_stmt->execute();
            $log_stmt->close();

            echo json_encode([
                'status' => 'security_questions_required',
                'message' => 'Please answer the security questions.',
                'student_id' => $student_id
            ]);
        }

    } else {
        echo json_encode(['status' => 'error', 'message' => 'Invalid student number or password']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid student number or password']);
}

$stmt->close();
$conn->close();
?>