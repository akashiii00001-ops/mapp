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

// --- 1. Verify Student Credentials & Fetch Profile Data ---
// JOIN tables to get Name and Batch Year for the app's UserProvider
$query = "
    SELECT 
        sl.student_id, sl.password, sl.email, 
        s.fname, s.lname, 
        b.batch_year
    FROM student_login sl
    JOIN students s ON sl.student_id = s.student_id
    LEFT JOIN batch b ON s.batch_id = b.batch_id
    WHERE sl.student_number = ?
";

$stmt = $conn->prepare($query);
$stmt->bind_param("s", $student_number);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $row = $result->fetch_assoc();
    $hashed_password_from_db = $row['password'];
    $student_id = $row['student_id'];
    $email = $row['email'];
    
    // Data for App State
    $fname = $row['fname'];
    $lname = $row['lname'];
    $batch_year = $row['batch_year'];

    if (password_verify($password_from_app, $hashed_password_from_db)) {
        
        // --- 2. Check if user has *ever* completed the first-time setup ---
        // We check the log for a previous successful 2FA or setup completion
        $log_action = "Mobile app 2FA successful"; 
        $log_check_stmt = $conn->prepare("SELECT 1 FROM student_activity_log WHERE student_id = ? AND action = ? LIMIT 1");
        $log_check_stmt->bind_param("is", $student_id, $log_action);
        $log_check_stmt->execute();
        $is_setup_complete = $log_check_stmt->get_result()->num_rows > 0;
        $log_check_stmt->close();

        if ($is_setup_complete) {
            // --- USER IS A RETURNING, VERIFIED USER ---

            if (!empty($email)) {
                // --- SCENARIO: User has Email -> LOGIN DIRECTLY (Skip 2FA) ---
                
                // Log this successful login
                $action = "Logged in via mobile app";
                $log_stmt = $conn->prepare("INSERT INTO student_activity_log (student_id, action) VALUES (?, ?)");
                $log_stmt->bind_param("is", $student_id, $action);
                $log_stmt->execute(); 
                $log_stmt->close();

                echo json_encode([
                    'status' => 'success',
                    'message' => 'Login successful',
                    'student_id' => $student_id,
                    'fname' => $fname,
                    'lname' => $lname,
                    'batch_year' => $batch_year
                ]);
                exit;

            } else {
                // --- SCENARIO: User verified before but Email is missing ---
                // Send them to security questions to re-establish identity/email
                $action = "Login step 1 success (email missing, security check required)";
                $log_stmt = $conn->prepare("INSERT INTO student_activity_log (student_id, action) VALUES (?, ?)");
                $log_stmt->bind_param("is", $student_id, $action);
                $log_stmt->execute(); $log_stmt->close();
                
                echo json_encode([
                    'status' => 'security_questions_required',
                    'message' => 'Please re-verify your identity to set up your email.',
                    'student_id' => $student_id
                ]);
                exit;
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