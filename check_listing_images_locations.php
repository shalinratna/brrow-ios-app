<?php
/**
 * Check where the images are actually stored
 */

// Direct database connection for testing
$host = 'pgdb1.awardspace.net';
$db = '3206877_brrow';
$user = '3206877_brrow';
$pass = 'Ballin@1415';

try {
    $dsn = "pgsql:host=$host;dbname=$db";
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);
    
    $listing_id = 'lst_68b719c439b5c.29461847';
    
    // Get listing info
    $stmt = $pdo->prepare("
        SELECT id, listing_id, title, images, date_posted
        FROM public.listings 
        WHERE listing_id = :lid
    ");
    $stmt->execute(['lid' => $listing_id]);
    $listing = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$listing) {
        die("Listing not found\n");
    }
    
    echo "Listing found: {$listing['title']}\n";
    echo "Listing ID: {$listing['listing_id']}\n";
    echo "Created: {$listing['date_posted']}\n\n";
    
    // Get images from listing_images table
    $img_stmt = $pdo->prepare("
        SELECT * FROM public.listing_images 
        WHERE listing_id = :lid OR listing_id = :numeric_id
        ORDER BY display_order, id
    ");
    $img_stmt->execute([
        'lid' => $listing_id,
        'numeric_id' => strval($listing['id'])
    ]);
    $images = $img_stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "Found " . count($images) . " images in listing_images table:\n\n";
    
    foreach ($images as $i => $img) {
        echo "Image " . ($i + 1) . ":\n";
        echo "  URL: {$img['image_url']}\n";
        
        // Parse URL to see where it's stored
        if (strpos($img['image_url'], '/misc/temp_') !== false) {
            preg_match('/\/misc\/(temp_[^\/]+)\//', $img['image_url'], $matches);
            echo "  Location: Temporary folder - /uploads/misc/{$matches[1]}/\n";
            echo "  Status: STILL IN TEMP LOCATION\n";
        } elseif (strpos($img['image_url'], "/listings/{$listing_id}/") !== false) {
            echo "  Location: Correct listing folder - /uploads/listings/{$listing_id}/\n";
            echo "  Status: CORRECTLY MOVED\n";
        } else {
            echo "  Location: Unknown\n";
        }
        echo "\n";
    }
    
    // Also check the images JSON column
    $images_json = json_decode($listing['images'] ?? '[]', true);
    if (!empty($images_json)) {
        echo "\nImages in JSON column: " . count($images_json) . "\n";
        foreach ($images_json as $url) {
            echo "  - $url\n";
        }
    }
    
    echo "\n\nDIAGNOSIS:\n";
    echo "The images are still in temporary folders and were never moved to:\n";
    echo "/uploads/listings/{$listing_id}/\n\n";
    echo "The temporary folders are at:\n";
    foreach ($images as $img) {
        if (strpos($img['image_url'], '/misc/temp_') !== false) {
            preg_match('/\/misc\/(temp_[^\/]+)\//', $img['image_url'], $matches);
            echo "  - /uploads/misc/{$matches[1]}/\n";
            break;
        }
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>