<?php
// Fix favorites table structure
require_once 'Brrowapp.com/api_config.php';

try {
    $db = getDB();
    
    // Drop existing table if it exists
    $db->exec("DROP TABLE IF EXISTS favorites CASCADE");
    
    // Create new favorites table with correct structure
    $db->exec("
        CREATE TABLE favorites (
            id SERIAL PRIMARY KEY,
            user_id INTEGER,
            user_api_id VARCHAR(255),
            listing_id INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_api_id, listing_id)
        )
    ");
    
    // Create indexes
    $db->exec("CREATE INDEX idx_favorites_user ON favorites(user_api_id)");
    $db->exec("CREATE INDEX idx_favorites_listing ON favorites(listing_id)");
    
    echo "✓ Favorites table created successfully\n";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>