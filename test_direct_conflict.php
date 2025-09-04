<?php
// Direct test of conflict detection logic
require_once __DIR__ . '/Brrowapp.com/brrow/api/config.php';

try {
    $db = DatabaseConnection::getInstance()->getConnection();
    
    // First, check what garage sales exist
    echo "Existing garage sales:\n";
    $check = $db->query("SELECT id, title, address, sale_date FROM garage_sales WHERE is_active = true");
    $existing = $check->fetchAll(PDO::FETCH_ASSOC);
    print_r($existing);
    
    // Test the conflict query directly
    $address = "123 Main Street, San Francisco, CA 94105";
    $latitude = 37.7918;
    $longitude = -122.3972;
    
    $conflict_check_query = "
        SELECT id, user_api_id, title, sale_date, address,
               latitude, longitude
        FROM garage_sales 
        WHERE (
            LOWER(address) = LOWER(:address)
            OR 
            (3959 * acos(
                cos(radians(:lat)) * cos(radians(latitude)) * 
                cos(radians(longitude) - radians(:lng)) + 
                sin(radians(:lat2)) * sin(radians(latitude))
            )) < 0.0095
        )
        AND is_active = true
    ";
    
    $stmt = $db->prepare($conflict_check_query);
    $stmt->execute([
        'address' => $address,
        'lat' => $latitude,
        'lng' => $longitude,
        'lat2' => $latitude
    ]);
    
    $conflicts = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "\nConflicts found for address '$address':\n";
    if (empty($conflicts)) {
        echo "No conflicts found\n";
    } else {
        print_r($conflicts);
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>