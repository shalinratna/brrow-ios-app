<?php
// Test database connection and garage sales
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
    
    echo "Connected to database successfully.\n\n";
    
    // Check if table exists
    $result = $db->query("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'garage_sales')")->fetchColumn();
    echo "Table exists: " . ($result ? 'Yes' : 'No') . "\n\n";
    
    if ($result) {
        // Get all garage sales
        $stmt = $db->query("SELECT id, title, sale_date, status FROM garage_sales ORDER BY id DESC LIMIT 10");
        $sales = $stmt->fetchAll();
        
        echo "Found " . count($sales) . " garage sales:\n";
        foreach ($sales as $sale) {
            echo "- ID: {$sale['id']}, Title: {$sale['title']}, Date: {$sale['sale_date']}, Status: {$sale['status']}\n";
        }
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>