<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");

// Database Connection
$conn = new mysqli('localhost', 'root', '', 'psu-bc-almns-db');
$conn->set_charset("utf8mb4"); // Ensure emoji/special char support

if ($conn->connect_error) {
    die(json_encode(['status' => 'error', 'message' => 'Database connection failed']));
}

// --- HELPER FUNCTION: LOG ACTIVITY ---
function logActivity($conn, $student_id, $action) {
    $stmt = $conn->prepare("INSERT INTO student_activity_log (student_id, action) VALUES (?, ?)");
    $stmt->bind_param("is", $student_id, $action);
    $stmt->execute();
    $stmt->close();
}

$data = json_decode(file_get_contents('php://input'), true);
$student_id = $data['student_id'] ?? 0;

if ($student_id > 0) {
    
    // 1. Log that the user is viewing/refreshing their profile
    logActivity($conn, $student_id, "Refreshed/Viewed Profile");

    // 2. Fetch Data
    $sql = "SELECT 
                s.fname, s.lname, s.mname, s.dob, s.profile_photo,
                b.batch_year,
                m.major_name,
                d.department_name,
                l.email,
                CONCAT(IFNULL(p.father_fname,''), ' ', IFNULL(p.father_lname,'')) as father_name,
                CONCAT(IFNULL(p.mother_fname,''), ' ', IFNULL(p.mother_lname,'')) as mother_name,
                (SELECT GROUP_CONCAT(award_title SEPARATOR ', ') FROM student_awards sa WHERE sa.student_id = s.student_id) as awards,
                CONCAT(IFNULL(a.barangay,''), ', ', IFNULL(a.municipality,''), ', ', IFNULL(a.province_city,'')) as full_address
            FROM students s 
            JOIN batch b ON s.batch_id = b.batch_id 
            LEFT JOIN majors m ON s.major_id = m.major_id
            LEFT JOIN department d ON s.department_id = d.department_id
            LEFT JOIN student_login l ON s.student_id = l.student_id 
            LEFT JOIN parents p ON s.student_id = p.student_id
            LEFT JOIN address a ON s.student_id = a.student_id
            WHERE s.student_id = ?";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $student_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($row = $result->fetch_assoc()) {
        // --- PROCESS DATA & HANDLE N/A ---

        // Parents
        $fName = trim($row['father_name']);
        $mName = trim($row['mother_name']);
        $parentsList = [];
        if (!empty($fName)) $parentsList[] = $fName;
        if (!empty($mName)) $parentsList[] = $mName;
        $row['parents_display'] = !empty($parentsList) ? implode(" & ", $parentsList) : "N/A";

        // Address
        $cleanAddress = trim($row['full_address'], ", ");
        if (empty($cleanAddress) || $cleanAddress === ", , " || $cleanAddress === "N/A, N/A, N/A") {
            $row['full_address'] = "N/A";
        } else {
            $row['full_address'] = $cleanAddress;
        }

        // Awards
        $row['awards'] = (!empty($row['awards'])) ? $row['awards'] : "None";

        // Major & Program
        $row['major_name'] = (!empty($row['major_name'])) ? $row['major_name'] : "N/A";
        $row['department_name'] = (!empty($row['department_name'])) ? $row['department_name'] : "N/A";
        
        // Birthdate
        $row['dob'] = (!empty($row['dob']) && $row['dob'] != '0000-00-00') ? $row['dob'] : "N/A";

        // Email
        $row['email'] = (!empty($row['email'])) ? $row['email'] : "N/A";

        // Profile Photo (Ensure it's not null)
        // Note: This just sends the filename. The Flutter app config appends the base URL.
        $row['profile_photo'] = (!empty($row['profile_photo'])) ? $row['profile_photo'] : null;

        echo json_encode(['status' => 'success', 'data' => $row]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Student not found']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid ID']);
}
$conn->close();
?>