<?php
// Database cleanup script - Delete all garage sales except mom's at 1340 Manley Dr
$host = 'pgdb1.awardspace.net';
$dbname = '3206877_brrow';
$user = '3206877_brrow';
$pass = 'Ballin@1415';

try {
    $dsn = "pgsql:host=$host;dbname=$dbname;port=5432";
    $db = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);
    
    echo "Connected to database successfully.\n";
    
    // First, let's see all garage sales
    echo "\n=== Current Garage Sales ===\n";
    $stmt = $db->query("SELECT id, title, address, location FROM garage_sales ORDER BY id");
    $sales = $stmt->fetchAll();
    
    foreach ($sales as $sale) {
        echo "ID: {$sale['id']} - {$sale['title']} at {$sale['address']}\n";
    }
    
    // Delete all garage sales EXCEPT the one at 1340 Manley Dr
    echo "\n=== Deleting Test Sales ===\n";
    $keepAddress = '1340 Manley Dr';
    
    $stmt = $db->prepare("
        DELETE FROM garage_sales 
        WHERE (address NOT LIKE :address1 AND location NOT LIKE :address2)
        OR title != 'Test garage sale'
        RETURNING id, title, address
    ");
    
    $stmt->execute([
        'address1' => '%' . $keepAddress . '%',
        'address2' => '%' . $keepAddress . '%'
    ]);
    
    $deleted = $stmt->fetchAll();
    echo "Deleted " . count($deleted) . " garage sales:\n";
    foreach ($deleted as $sale) {
        echo "  - Deleted: {$sale['title']} at {$sale['address']}\n";
    }
    
    // Show remaining garage sales
    echo "\n=== Remaining Garage Sales ===\n";
    $stmt = $db->query("SELECT id, title, address, location FROM garage_sales ORDER BY id");
    $remaining = $stmt->fetchAll();
    
    if (empty($remaining)) {
        echo "No garage sales remaining in database.\n";
    } else {
        foreach ($remaining as $sale) {
            echo "ID: {$sale['id']} - {$sale['title']} at {$sale['address']}\n";
        }
    }
    
    echo "\nCleanup complete!\n";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>