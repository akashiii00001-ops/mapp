<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");

$conn = new mysqli('localhost', 'root', '', 'psu-bc-almns-db');

if ($conn->connect_error) {
    die(json_encode(['status' => 'error', 'message' => 'Database connection failed']));
}

$data = json_decode(file_get_contents('php://input'), true);
$student_id = $data['student_id'] ?? 0;

if ($student_id > 0) {
    // Use LEFT JOIN so we get student info even if parents/address are missing
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
        // Format Parents
        $parents = [];
        if (!empty(trim($row['father_name']))) $parents[] = trim($row['father_name']);
        if (!empty(trim($row['mother_name']))) $parents[] = trim($row['mother_name']);
        $row['parents_display'] = !empty($parents) ? implode(" & ", $parents) : "N/A";

        // Clean Address
        $row['full_address'] = trim($row['full_address'], ", ");
        if ($row['full_address'] == "" || $row['full_address'] == ", , ") $row['full_address'] = "N/A";

        echo json_encode(['status' => 'success', 'data' => $row]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Student not found']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid ID']);
}
$conn->close();
?>