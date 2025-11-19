<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

$conn = new mysqli('localhost', 'root', '', 'psu-bc-almns-db');

if ($conn->connect_error) {
    echo json_encode([]);
    exit;
}

$industries = [];
$sql = "SELECT industry_id, name FROM industries WHERE deactivated_at IS NULL ORDER BY name ASC";
$result = $conn->query($sql);

while($row = $result->fetch_assoc()) {
    $industries[] = $row;
}

echo json_encode($industries);
$conn->close();
?>