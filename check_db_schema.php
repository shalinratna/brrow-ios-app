<?php
require_once 'Brrowapp.com/config/db_config.php';

try {
    $pdo = new PDO(
        "pgsql:host=" . DB_HOST . ";dbname=" . DB_NAME,
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
        ]
    );
    
    echo "=== Database Schema Check ===\n\n";
    
    // Check transactions table columns
    echo "TRANSACTIONS TABLE COLUMNS:\n";
    echo "----------------------------\n";
    $stmt = $pdo->query("
        SELECT column_name, data_type, is_nullable 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'transactions'
        ORDER BY ordinal_position
    ");
    $columns = $stmt->fetchAll();
    foreach ($columns as $col) {
        echo sprintf("- %s (%s) %s\n", 
            $col['column_name'], 
            $col['data_type'],
            $col['is_nullable'] == 'NO' ? 'NOT NULL' : 'NULL'
        );
    }
    
    // Check if admin_actions table exists
    echo "\n\nADMIN_ACTIONS TABLE CHECK:\n";
    echo "----------------------------\n";
    $stmt = $pdo->query("
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'admin_actions'
        )
    ");
    $exists = $stmt->fetchColumn();
    if ($exists) {
        echo "✓ admin_actions table exists\n";
        
        // Show columns
        $stmt = $pdo->query("
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'admin_actions'
            ORDER BY ordinal_position
        ");
        $columns = $stmt->fetchAll();
        foreach ($columns as $col) {
            echo sprintf("  - %s (%s)\n", $col['column_name'], $col['data_type']);
        }
    } else {
        echo "✗ admin_actions table does not exist\n";
    }
    
    // Check listings table for status column
    echo "\n\nLISTINGS TABLE STATUS COLUMN:\n";
    echo "----------------------------\n";
    $stmt = $pdo->query("
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'listings'
        AND column_name = 'status'
    ");
    $status_col = $stmt->fetch();
    if ($status_col) {
        echo sprintf("✓ status column exists (%s)\n", $status_col['data_type']);
    } else {
        echo "✗ status column does not exist\n";
    }
    
    // Check for deleted_at column
    $stmt = $pdo->query("
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'listings'
        AND column_name = 'deleted_at'
    ");
    $deleted_col = $stmt->fetch();
    if ($deleted_col) {
        echo sprintf("✓ deleted_at column exists (%s)\n", $deleted_col['data_type']);
    } else {
        echo "✗ deleted_at column does not exist\n";
    }
    
    // Sample transaction data to understand structure
    echo "\n\nSAMPLE TRANSACTION DATA:\n";
    echo "----------------------------\n";
    $stmt = $pdo->query("SELECT * FROM public.transactions LIMIT 1");
    $transaction = $stmt->fetch();
    if ($transaction) {
        foreach ($transaction as $key => $value) {
            echo sprintf("- %s: %s\n", $key, $value ?: 'NULL');
        }
    } else {
        echo "No transactions found in database\n";
    }
    
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>